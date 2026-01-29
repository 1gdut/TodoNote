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
}
