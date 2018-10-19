# Cache
A wrap around NSCache.

The NSCache functionality with a typed Swift API.

# Typed safe
```swift
let cache: Cache<String, UIImage> = [:]
cache["image"] = UIImage()
let image = cache["image"]
```

# O(1) Access to keys
```swift
let keys = cache.keys
```

# Sequence and Collection protocol conformance
```swift
let values = cache.compactMap { $0.value }
```

# CacheDelegate for evicted values
```swift
cache.delegate = self
```
