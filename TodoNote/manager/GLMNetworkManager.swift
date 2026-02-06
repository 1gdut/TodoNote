import Foundation
import CryptoKit

extension Data {
    func base64UrlEncodedString() -> String {
        let base64 = self.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

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

// MARK: - Chat Completion Models

struct GLMChatMessage: Codable {
    let role: String
    let content: String
}

struct GLMRetrievalObject: Codable {
    let knowledge_id: String
    let prompt_template: String?
}

struct GLMTool: Codable {
    let type: String // "retrieval", "function", "web_search"
    let retrieval: GLMRetrievalObject?
}

struct GLMChatRequest: Codable {
    let model: String
    let messages: [GLMChatMessage]
    let stream: Bool?
    let temperature: Double?
    let top_p: Double?
    let max_tokens: Int?
    let tools: [GLMTool]?
    let tool_choice: String?
    let request_id: String?
}

struct GLMChatUsage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

struct GLMChatChoice: Codable {
    let index: Int
    let message: GLMChatMessage? // For non-stream
    let delta: GLMChatMessage?   // For stream
    let finish_reason: String?
}

struct GLMChatResponse: Codable {
    let id: String?
    let created: Int?
    let model: String?
    let choices: [GLMChatChoice]?
    let usage: GLMChatUsage?
    let code: Int?
    let msg: String?
    
    var error: Error? {
        if let code = code, code != 200 {
            return NSError(domain: "GLM API Error", code: code, userInfo: [NSLocalizedDescriptionKey: msg ?? "Unknown error"])
        }
        return nil
    }
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
    
    private func getAuthorizationHeader() -> String {
        let key = apiKey
        guard !key.isEmpty else { return "" }
        
        let parts = key.components(separatedBy: ".")
        guard parts.count == 2 else { return "Bearer \(key)" } // Fallback to raw key if format doesn't match
        
        let id = parts[0]
        let secret = parts[1]
        
        // 1. Header
        let headerDict: [String: Any] = ["alg": "HS256", "sign_type": "SIGN"]
        guard let headerData = try? JSONSerialization.data(withJSONObject: headerDict) else { return "" }
        let headerString = headerData.base64UrlEncodedString()
        
        // 2. Payload
        // Using milliseconds for GLM API
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let exp = now + 3600 * 1000 // 1 hour validity
        
        let payloadDict: [String: Any] = [
            "api_key": id,
            "exp": exp,
            "timestamp": now
        ]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDict) else { return "" }
        let payloadString = payloadData.base64UrlEncodedString()
        
        // 3. Signature
        let contentToSign = "\(headerString).\(payloadString)"
        guard let secretData = secret.data(using: .utf8),
              let contentData = contentToSign.data(using: .utf8) else { return "" }
        
        let symmetricKey = SymmetricKey(data: secretData)
        let signature = HMAC<SHA256>.authenticationCode(for: contentData, using: symmetricKey)
        let signatureString = Data(signature).base64UrlEncodedString()
        
        let jwt = "\(headerString).\(payloadString).\(signatureString)"
        return "Bearer \(jwt)"
    }
    
    private init() {}

    func chatCompletion(model: String = "glm-4.7",
                        messages: [GLMChatMessage],
                        tools: [GLMTool]? = nil,
                        toolChoice: String? = nil,
                        stream: Bool = false,
                        temperature: Double? = nil,
                        topP: Double? = nil,
                        maxTokens: Int? = 131070,
                        requestId: String? = nil,
                        completion: @escaping (Result<GLMChatResponse, Error>) -> Void) {
        
        let endpoint = "paas/v4/chat/completions"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 180 
        request.setValue(getAuthorizationHeader(), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = GLMChatRequest(
            model: model,
            messages: messages,
            stream: stream,
            temperature: temperature,
            top_p: topP,
            max_tokens: maxTokens,
            tools: tools,
            tool_choice: toolChoice,
            request_id: requestId
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
                let decodedResponse = try JSONDecoder().decode(GLMChatResponse.self, from: data)
                if let err = decodedResponse.error {
                    completion(.failure(err))
                    return
                }
                completion(.success(decodedResponse))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Stream Chat
    
    func streamChatCompletion(model: String = "glm-4.7",
                              messages: [GLMChatMessage],
                              tools: [GLMTool]? = nil,
                              toolChoice: String? = nil,
                              temperature: Double? = nil,
                              topP: Double? = nil,
                              maxTokens: Int? = 1024,
                              requestId: String? = nil) -> AsyncThrowingStream<String, Error> {
        
        return AsyncThrowingStream { continuation in
            Task {
                let endpoint = "paas/v4/chat/completions"
                guard let url = URL(string: baseURL + endpoint) else {
                    continuation.finish(throwing: NSError(domain: "Invalid URL", code: -1, userInfo: nil))
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = 180 
                request.setValue(GLMNetworkManager.shared.getAuthorizationHeader(), forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                
                let requestBody = GLMChatRequest(
                    model: model,
                    messages: messages,
                    stream: true,
                    temperature: temperature,
                    top_p: topP,
                    max_tokens: maxTokens,
                    tools: tools,
                    tool_choice: tools != nil ? (toolChoice ?? "auto") : nil,
                    request_id: requestId
                )
                
                do {
                    request.httpBody = try JSONEncoder().encode(requestBody)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                        continuation.finish(throwing: NSError(domain: "GLM API Error", code: statusCode, userInfo: nil))
                        return
                    }
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonStr = line.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
                            if jsonStr == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            
                            guard let data = jsonStr.data(using: .utf8) else { continue }
                            
                            do {
                                let chunk = try JSONDecoder().decode(GLMChatResponse.self, from: data)
                                if let content = chunk.choices?.first?.delta?.content {
                                    continuation.yield(content)
                                }
                            } catch {
                                // Ignore json parse errors for individual lines trying to keep stream alive
                                print("Stream decode error for line: \(jsonStr), error: \(error)")
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
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
