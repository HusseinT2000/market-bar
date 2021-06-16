//
//  Settings.swift
//  marketbar
//
//  Created by Daniil Manin on 27.12.2020.
//

import Foundation

let githubLink = URL(string: "https://github.com/manindaniil/market-bar")!

struct Settings: Codable {
	
	var tickers: [Ticker] = []
	var updateInterval: TimeInterval = 30.0
	var changesInPercentage: Bool = false
	var showOnlyOneTicker: Bool = false
	var showTickerName: Bool = true
	var showPremarketInBar: Bool = false
	
	static var maxNumberOfTickers: Int = 10
}
