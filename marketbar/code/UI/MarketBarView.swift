//
//  MarketBarView.swift
//  marketbar
//
//  Created by Daniil Manin on 27.12.2020.
//

import AppKit
import Combine

final class MarketBarView: NSView {
	
	private let manager = MarketManager.shared
	
	private var menuItem: NSMenu?
	private let statusItem = NSStatusBar.system.statusItem(withLength: -1)
	private var cancellables: Set<AnyCancellable> = []
	
	private var timer: Timer?
	
	func configure(menu: NSMenu?) {
		guard let _ = statusItem.button else {
			return NSApp.terminate(.none)
		}
		
		update()
		menuItem = menu
		
		manager.didUpdateSettings
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				self?.update()
			}
			.store(in: &cancellables)
		
		manager.didUpdateTickers
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				guard let tickersCount = self?.manager.tickers.count else { return }
				guard tickersCount < 3 else { return }
				self?.update()
			}
			.store(in: &cancellables)
	}
	
	// MARK: - Private
	
	private func update() {
		prepare()
		configureStatusItem()
	}
	
	private func configureStatusItem() {
		guard !manager.showOnlyOneTicker else {
			configureOnlyOneStatusItem()
			return
		}
		let marketButton = MarketButton(tickers: manager.tickers, originX: 0.0)
		statusItem.button?.addSubview(marketButton)
		
		if manager.tickers.count > 2 {
			marketButton.fadeAnimation(alphaValue: 1.0)
			animationMode(marketButton: marketButton)
		} else {
			nonAnimationMode(marketButton: marketButton)
		}
	}
	
	private func configureOnlyOneStatusItem() {
		guard let firstTicker = manager.tickers.first else { return }
		let marketButton = MarketButton(tickers: [firstTicker], originX: 0.0)
		statusItem.button?.addSubview(marketButton)
		statusItem.button?.frame.size.width = marketButton.frame.size.width
		timer?.invalidate()
		timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(fireTimer), userInfo: .none, repeats: true)
	}
	
	@objc private func fireTimer() {
		guard let marketButton = statusItem.button?.subviews.first(where: { $0 is MarketButton }) as? MarketButton else { return }
		guard let ticker = marketButton.tickers.first else { return }
		guard let tickerIndex = manager.tickers.firstIndex(where: { $0.symbol == ticker.symbol }) else { return }
		let nextIndex = tickerIndex + 1 >= manager.tickers.count ? 0 : (tickerIndex + 1)
		marketButton.set(ticker: manager.tickers[nextIndex])
		statusItem.button?.frame.size.width = marketButton.frame.size.width
	}
	
	// MARK: - Animations
	
	private func animationMode(marketButton: MarketButton) {
		statusItem.button?.frame.size.width = 160.0
		nextMarketButton(originX: marketButton.frame.width)
		marketButton.scrollAnimation(duration: TimeInterval(manager.tickers.count) * 5.0) { [weak self] in
			self?.nextMarketButton(originX: marketButton.frame.width)
		}
	}
	
	private func nonAnimationMode(marketButton: MarketButton) {
		statusItem.button?.frame.size.width = marketButton.frame.size.width
	}
	
	// MARK: - Market Button
	
	private func nextMarketButton(originX: CGFloat) {
		let marketButton = MarketButton(tickers: manager.tickers, originX: originX)
		statusItem.button?.addSubview(marketButton)
		marketButton.scrollAnimation(duration: TimeInterval(manager.tickers.count) * 10.0) { [weak self] in
			self?.nextMarketButton(originX: marketButton.frame.width)
		}
	}

	// MARK: - Other
	
	private func prepare() {
		timer?.invalidate()
		removeMarketButtons()
	}
	
	private func removeMarketButtons() {
		statusItem.button?.subviews
			.compactMap { $0 as? MarketButton }
			.forEach { remove(button: $0) }
	}
	
	private func remove(button: MarketButton?) {
		if manager.tickers.count > 2 {
			button?.fadeAnimation(alphaValue: 0.0) {
				button?.removeFromSuperview()
			}
		} else {
			button?.removeFromSuperview()
		}
	}
}
