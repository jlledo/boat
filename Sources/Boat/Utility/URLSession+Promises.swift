import Foundation
import Promises

extension URLSession {
    func fetchData(from url: URL) -> Promise<(data: Data, response: HTTPURLResponse)> {
        return Promise<(data: Data, response: HTTPURLResponse)>() { fulfill, reject in
            self.dataTask(with: url) { data, response, error in
                if let error = error {
                    reject(error)
                    return
                }

                if let response = response as? HTTPURLResponse {
                    if let data = data {
                        fulfill((data, response))
                    } else {
                        reject(BoatError.noDataReceived(
                            url: url.absoluteString,
                            code: response.statusCode
                        ))
                    }
                } else {
                    reject(BoatError.notHttpResponse(url: url.absoluteString))
                }
            }.resume()
        }
    }

    func upload(data: Data, with request: URLRequest) ->
        Promise<(data: Data, response: HTTPURLResponse)>
    {
        return Promise<(data: Data, response: HTTPURLResponse)>() { fulfill, reject in
            self.uploadTask(with: request, from: data) { data, response, error in
                if let error = error {
                    reject(error)
                    return
                }

                if let response = response as? HTTPURLResponse {
                    if let data = data {
                        fulfill((data, response))
                    } else {
                        reject(BoatError.noDataReceived(
                            url: response.url?.absoluteString ?? "Response URL not available",
                            code: response.statusCode
                        ))
                    }
                } else {
                    reject(BoatError.notHttpResponse(
                        url: response?.url?.absoluteString ?? "Response URL not available"
                    ))
                }
            }.resume()
        }
    }
}
