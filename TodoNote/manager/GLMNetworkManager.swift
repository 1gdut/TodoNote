import Foundation

struct GLMKnowledgeBaseRequest: Codable {
    let embedding_id: Int
    let name: String
    let description: String?
    let background: String?
    let icon: String?
}

struct GLMKnowledgeBaseResponseData: Codable {
    let id: String
}

struct GLMKnowledgeBaseResponse: Codable {
    let code: Int
    let message: String
    let data: GLMKnowledgeBaseResponseData?
    let timestamp: Int
}

struct GLMUploadResponseData: Codable {
    struct SuccessInfo: Codable {
        let documentId: String
        let fileName: String
    }
    struct FailedInfo: Codable {
        let fileName: String
        let failReason: String
    }
    let successInfos: [SuccessInfo]?
    let failedInfos: [FailedInfo]?
}

struct GLMUploadResponse: Codable {
    let code: Int
    let message: String
    let data: GLMUploadResponseData?
    let timestamp: Int
}

struct GLMRetrievalRequest: Codable {
    let query: String
    let knowledge_ids: [String]
    let request_id: String?
    let document_ids: [String]?
    let top_k: Int?
    let top_n: Int?
    let recall_method: String? // "embedding", "keyword", "mixed"
    let recall_ratio: Int?
    let rerank_status: Int? // 0 or 1
    let rerank_model: String? // "rerank", "rerank-pro"
    let fractional_threshold: Double?
}

struct GLMRetrievalMetadata: Codable {
    let _id: String
    let knowledge_id: String
    let doc_id: String
    let doc_name: String
    let doc_url: String
    let contextual_text: String?
}

struct GLMRetrievalResult: Codable {
    let text: String
    let score: Double
    let metadata: GLMRetrievalMetadata
}

struct GLMRetrievalResponse: Codable {
    let code: Int
    let message: String
    let data: [GLMRetrievalResult]?
    let timestamp: Int
}

class GLMNetworkManager {
    static let shared = GLMNetworkManager()
    
    // User provided API Key from Info.plist
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GLM_API_KEY") as? String else {
            print("Error: GLM_API_KEY not found in Info.plist")
            return ""
        }
        return key
    }
    private let baseURL = "https://open.bigmodel.cn/api/"
    
    private init() {}
    
    func createKnowledgeBase(name: String, 
                             description: String? = nil, 
                             embeddingId: Int = 3, 
                             embedding_model: String = "Embedding-3-pro",
                             contextual: Int = 1,
                             background: String? = "blue", 
                             icon: String? = "question", 
                             completion: @escaping (Result<String, Error>) -> Void) {
        
        let endpoint = "llm-application/open/knowledge"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = GLMKnowledgeBaseRequest(
            embedding_id: embeddingId,
            name: name,
            description: description,
            background: background, // options: blue, red, orange, purple, sky, green, yellow
            icon: icon // options: question, book, seal, wrench, tag, horn, house
        )
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(GLMKnowledgeBaseResponse.self, from: data)
                if decodedResponse.code == 200, let knowledgeBaseId = decodedResponse.data?.id {
                    completion(.success(knowledgeBaseId))
                } else {
                    let message = decodedResponse.message
                    completion(.failure(NSError(domain: "API Error", code: decodedResponse.code, userInfo: [NSLocalizedDescriptionKey: message])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

    func uploadDocument(knowledgeBaseId: String,
                        fileUrl: URL,
                        knowledgeType: Int = 1,
                        completion: @escaping (Result<GLMUploadResponseData, Error>) -> Void) {
        
        // Construct Endpoint
        let endpoint = "llm-application/open/document/upload_document/\(knowledgeBaseId)"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Multipart/form-data boundary
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Load File Data
        guard let fileData = try? Data(contentsOf: fileUrl) else {
            completion(.failure(NSError(domain: "File Read Error", code: -1, userInfo: nil)))
            return
        }
        
        let filename = fileUrl.lastPathComponent
        // Defaulting to generic binary stream, but server might auto-detect based on extension
        let mimeType = "application/octet-stream" 
        
        var body = Data()
        
        // 1. Add File Data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 2. Add Other Parameters (knowledge_type)
        let params: [String: String] = [
            "knowledge_type": "\(knowledgeType)"
        ]
        
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // End Boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(GLMUploadResponse.self, from: data)
                if decodedResponse.code == 200, let responseData = decodedResponse.data {
                    completion(.success(responseData))
                } else {
                    let message = decodedResponse.message
                    completion(.failure(NSError(domain: "API Error", code: decodedResponse.code, userInfo: [NSLocalizedDescriptionKey: message])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func deleteDocument(documentId: String,
                        completion: @escaping (Bool, String?) -> Void) {
        
        let endpoint = "llm-application/open/document/\(documentId)"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let data = data else {
                completion(false, "No Data")
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(GLMKnowledgeBaseResponse.self, from: data)
                if decodedResponse.code == 200 {
                    completion(true, nil)
                } else {
                    completion(false, decodedResponse.message)
                }
            } catch {
                completion(false, error.localizedDescription)
            }
        }
        
        task.resume()
    }

    func retrieveFromKnowledgeBase(query: String,
                                   knowledgeId: String,
                                   requestId: String? = nil,
                                   documentIds: [String]? = nil,
                                   topK: Int = 8,
                                   completion: @escaping (Result<[GLMRetrievalResult], Error>) -> Void) {
        
        let endpoint = "llm-application/open/knowledge/retrieve"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = GLMRetrievalRequest(
            query: query,
            knowledge_ids: [knowledgeId],
            request_id: requestId,
            document_ids: documentIds,
            top_k: topK,
            top_n: nil,
            recall_method: "mixed",
            recall_ratio: 80,
            rerank_status: 1, 
            rerank_model: "rerank-pro",
            fractional_threshold: nil
        )
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(GLMRetrievalResponse.self, from: data)
                if decodedResponse.code == 200, let results = decodedResponse.data {
                    completion(.success(results))
                } else {
                    let message = decodedResponse.message
                    completion(.failure(NSError(domain: "API Error", code: decodedResponse.code, userInfo: [NSLocalizedDescriptionKey: message])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
