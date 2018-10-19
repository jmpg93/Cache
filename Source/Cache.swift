//
//  Cache.swift
//  Cache
//
//  Created by jmpuerta on 18/10/18.
//  Copyright © 2018 Tuenti. All rights reserved.
//

import Foundation
import UIKit

protocol CacheDelegate: class {
	func cache<Key: Hashable, Value>(_ cache: Cache<Key, Value>, willEvictValue value: Value)
}

open class Cache<Key: Hashable, Value>: NSObject, NSCacheDelegate, ExpressibleByDictionaryLiteral {
	private typealias KeyBox = Cache.Box<Key>
	private typealias ValueBox = Cache.Box<Value>

	// MARK: Box definition

	private class Box<T>: NSObject {
		let value: T

		init(_ value: T) {
			self.value = value
		}

		override func isEqual(_ object: Any?) -> Bool {
			guard let otherKey = object as? KeyBox else { return false }
			guard let key = self as? KeyBox else { return false }
			return key.value == otherKey.value
		}

		override var hash: Int {
			guard let value = self as? ValueBox else { return 0 }
			return value.hashValue
		}
	}

	private (set)var keys: Set<Key> = []
	private lazy var cache = NSCache<KeyBox, ValueBox>(delegate: self)

	weak open var delegate: CacheDelegate?

	// MARK: Init

	convenience init<S: Sequence>(_ sequence: S) where S.Iterator.Element == (key: Key, value: Value) {
		self.init()

		for (key, value) in sequence {
			self[key] = value
		}
	}

	// MARK: ExpressibleByDictionaryLiteral

	required convenience init(dictionaryLiteral elements: (Key, Value)...) {
		self.init(elements.map { (key: $0.0, value: $0.1) })
	}

	// MARK: NSCacheDelegate

	func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
		guard let value = obj as? Value else { return }
		delegate?.cache(self, willEvictValue: value)
	}
}

// MARK: Properties

extension Cache {
	open func set(_ value: Value, for key: Key, cost: Int) {
		self[key, cost] = value
	}

	open func set(_ value: Value, for key: Key) {
		self[key] = value
	}

	open func get(for key: Key) -> Value? {
		return self[key]
	}

	open func remove(for key: Key) {
		self[key] = nil
	}

	open func removeAll() {
		keys.forEach(remove)
	}

	open subscript(key: Key, cost: Int) -> Value? {
		get {
			return cache.object(forKey: Box(key))?.value
		}

		set(newValue) {
			if let value = newValue {
				keys.insert(key)
				cache.setObject(Box(value), forKey: Box(key), cost: cost)
			} else {
				keys.remove(key)
				cache.removeObject(forKey: Box(key))
			}
		}
	}

	open subscript(key: Key) -> Value? {
		get {
			return cache.object(forKey: Box(key))?.value
		}

		set(newValue) {
			if let value = newValue {
				keys.insert(key)
				cache.setObject(Box(value), forKey: Box(key))
			} else {
				keys.remove(key)
				cache.removeObject(forKey: Box(key))
			}
		}
	}
}

// MARK: Properties

extension Cache {
	open var name: String {
		set {
			cache.name = newValue
		}

		get {
			return cache.name
		}
	}

	open var totalCostLimit: Int {
		set {
			cache.totalCostLimit = newValue
		}

		get {
			return cache.totalCostLimit
		}
	}

	open var countLimit: Int {
		set {
			cache.countLimit = newValue
		}

		get {
			return cache.countLimit
		}
	}

	open var evictsObjectsWithDiscardedContent: Bool {
		set {
			cache.evictsObjectsWithDiscardedContent = newValue
		}

		get {
			return cache.evictsObjectsWithDiscardedContent
		}
	}
}

// MARK: Sequence

extension Cache: Sequence {
	typealias Iterator = AnyIterator<(key: Key, value: Value)>

	func makeIterator() -> Iterator {
		// Make a copy of the keys
		let keys = self.keys

		// Create the iterator over the new keys
		var iterator = keys.makeIterator()

		// Function that clears the evicted keys and retrieve the next element.
		func next() -> (key: Key, value: Value)? {
			guard let key = iterator.next() else { return nil }

			if let value = self[key] {
				return (key: key, value: value)
			} else {
				// Remove evicted key.
				self.keys.remove(key)
				return next()
			}
		}

		// Return the iterator
		return AnyIterator(next)
	}
}

// MARK: Collection

extension Cache: Collection {
	struct Index: Comparable {
		fileprivate let index: Set<Key>.Index

		fileprivate init(_ dictionaryIndex: Set<Key>.Index) {
			self.index = dictionaryIndex
		}

		static func == (lhs: Index, rhs: Index) -> Bool {
			return lhs.index == rhs.index
		}

		static func < (lhs: Index, rhs: Index) -> Bool {
			return lhs.index < rhs.index
		}
	}

	var startIndex: Index {
		return Index(keys.startIndex)
	}

	var endIndex: Index {
		return Index(keys.endIndex)
	}

	subscript (position: Index) -> Iterator.Element {
		let key = keys[position.index]

		guard let value = self[key] else { fatalError("Invalid key") }

		return (key: key, value: value)
	}

	func index(after position: Index) -> Index {
		return Index(keys.index(after: position.index))
	}
}

// MARK: NSCache convenience

extension NSCache {
	@objc convenience init(delegate: NSCacheDelegate) {
		self.init()

		self.delegate = delegate
	}
}
