import Foundation

class GroqWhisperService {
    enum ServiceError: Error, LocalizedError {
        case invalidURL
        case missingAPIKey
        case badResponse(statusCode: Int)
        case decodingError
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Некорректный URL API"
            case .missingAPIKey: return "API-ключ Groq не настроен"
            case .badResponse(let code): return "Ошибка сервера Groq: \(code)"
            case .decodingError: return "Не удалось распознать ответ сервера"
            case .noData: return "Сервер вернул пустой ответ"
            }
        }
    }
    
    func transcribe(fileURL: URL, apiKey: String, language: String, prompt: String, temperature: Double, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(ServiceError.missingAPIKey))
            return
        }
        
        guard let url = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions") else {
            completion(.failure(ServiceError.invalidURL))
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-large-v3-turbo\r\n".data(using: .utf8)!)
        
        // Temperature field (dynamic value from settings)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(String(format: "%.1f", temperature))\r\n".data(using: .utf8)!)
        
        // Prompt field (for punctuation guide and custom vocabulary)
        if !prompt.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(prompt)\r\n".data(using: .utf8)!)
        }
        
        // Language field (if not auto)
        if language != "auto" && !language.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // File field
        do {
            let fileData = try Data(contentsOf: fileURL)
            let mimeType = "audio/m4a"
            let fileName = fileURL.lastPathComponent
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            completion(.failure(error))
            return
        }
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ServiceError.decodingError))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(ServiceError.badResponse(statusCode: httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(ServiceError.noData))
                return
            }
            
            do {
                struct GroqResponse: Codable {
                    let text: String
                }
                
                let decoder = JSONDecoder()
                let result = try decoder.decode(GroqResponse.self, from: data)
                completion(.success(result.text))
            } catch {
                completion(.failure(ServiceError.decodingError))
            }
        }
        
        task.resume()
    }
}
