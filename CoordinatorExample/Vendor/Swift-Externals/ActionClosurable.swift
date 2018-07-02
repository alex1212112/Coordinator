//
//  ActionClosurable.swift
//  ActionClosurable
//
//  Created by Yoshitaka Seki on 2016/04/11.
//  Copyright © 2016年 Yoshitaka Seki. All rights reserved.
//

import UIKit

private class Actor<T> {
	@objc func act(sender: AnyObject) { closure(sender as! T) }
	private let closure: (T) -> Void
	init(acts closure: @escaping (T) -> Void) {
		self.closure = closure
	}
}

private class GreenRoom {
	fileprivate var actors: [Any] = []
}
private var GreenRoomKey: UInt32 = 893

private func register<T>(_ actor: Actor<T>, to object: AnyObject) {
	let room = objc_getAssociatedObject(object, &GreenRoomKey) as? GreenRoom ?? {
		let room = GreenRoom()
		objc_setAssociatedObject(object, &GreenRoomKey, room, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return room
		}()
	room.actors.append(actor)
}

public protocol ActionClosurable {}
public extension ActionClosurable where Self: AnyObject {
	public func convert(closure: @escaping (Self) -> Void, toConfiguration configure: (AnyObject, Selector) -> Void) {
		let actor = Actor(acts: closure)
		configure(actor, #selector(Actor<AnyObject>.act(sender:)))
		register(actor, to: self)
	}
	public static func convert(closure: @escaping (Self) -> Void, toConfiguration configure: (AnyObject, Selector) -> Self) -> Self {
		let actor = Actor(acts: closure)
		let instance = configure(actor, #selector(Actor<AnyObject>.act(sender:)))
		register(actor, to: instance)
		return instance
	}
}

extension NSObject: ActionClosurable {}



//
//  Extensions.swift
//  ActionClosurable
//
//  Created by Yoshitaka Seki on 2016/04/11.
//  Copyright © 2016年 Yoshitaka Seki. All rights reserved.
//


extension ActionClosurable where Self: UIControl {
	public func on(_ controlEvents: UIControlEvents, closure: @escaping (Self) -> Void) {
		convert(closure: closure, toConfiguration: {
			self.addTarget($0, action: $1, for: controlEvents)
		})
	}
}

extension ActionClosurable where Self: UIButton {
	public func onTap(_ closure: @escaping (Self) -> Void) {
		convert(closure: closure, toConfiguration: {
			self.addTarget($0, action: $1, for: .touchUpInside)
		})
	}
}


extension ActionClosurable where Self: UIGestureRecognizer {
	public func onGesture(_ closure: @escaping (Self) -> Void) {
		convert(closure: closure, toConfiguration: {
			self.addTarget($0, action: $1)
		})
	}
	public init(closure: @escaping (Self) -> Void) {
		self.init()
		onGesture(closure)
	}
}

extension ActionClosurable where Self: UIBarButtonItem {
	public init(title: String, style: UIBarButtonItemStyle = .plain, closure: @escaping (Self) -> Void) {
		self.init()
		self.title = title
		self.style = style
		self.onTap(closure)
	}
	public init(image: UIImage?, style: UIBarButtonItemStyle = .plain, closure: @escaping (Self) -> Void) {
		self.init()
		self.image = image
		self.style = style
		self.onTap(closure)
	}
	public func onTap(_ closure: @escaping (Self) -> Void) {
		convert(closure: closure, toConfiguration: {
			self.target = $0
			self.action = $1
		})
	}
}
