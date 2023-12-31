//
//  MenuController.swift
//  rest
//
//  Created by Omar Osama on 09/08/2023.
//

import Foundation


class MenuController{
    let baseURL = URL(string: "http://localhost:8080/")!
    static let shared = MenuController()
    var order = Order(){
        didSet{
            NotificationCenter.default.post(name: MenuController.orderUpdatedNotification, object: nil)
        }
    }
    static let orderUpdatedNotification =
       Notification.Name("MenuController.orderUpdated")

    enum MenuControllerError: Error, LocalizedError {
        case categoriesNotFound
        case menuItemsNotFound
        case orderRequestFailed

    }
    
    //fetch categories
    func fetchCategories () async throws -> [String]
    {
        let categoriesURL = baseURL.appendingPathComponent("categories")
        let (data,response) = try await URLSession.shared.data(from: categoriesURL)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else{
            throw MenuControllerError.categoriesNotFound
        }
        
        let decoder = JSONDecoder()
        let categoriesResponse = try decoder.decode(CategoriesResponse.self,
           from: data)
        return categoriesResponse.categories
    }
    
    //fetch menu
    func fetchMenuItems(forCategory categoryName: String) async throws ->[MenuItem]{
        let baseMenuUrl = baseURL.appendingPathComponent("menu")
        var components = URLComponents(url: baseMenuUrl, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "category", value: categoryName)]
        let menuUrl = components.url!
        let (data,response) = try await URLSession.shared.data(from: menuUrl)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else{
            throw MenuControllerError.menuItemsNotFound
        }
        
        let decoder = JSONDecoder()
        let menuResponse = try decoder.decode(MenuResponse.self,
           from: data)
        
        return menuResponse.items
    }
    
    typealias MinutesToPrepare = Int
    //fetch orders
    func submitOrder(forMenuIDs menuIDs: [Int]) async throws -> MinutesToPrepare {
        let orderURL = baseURL.appendingPathComponent("order")
        var request = URLRequest(url: orderURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let menuIdsDict = ["menuIds": menuIDs]
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(menuIdsDict)
        request.httpBody = jsonData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else{
            throw MenuControllerError.orderRequestFailed
        }
        
        let decoder = JSONDecoder()
        let orderResponse = try decoder.decode(OrderResponse.self,
           from: data)
        return orderResponse.prepTime
    }
}

