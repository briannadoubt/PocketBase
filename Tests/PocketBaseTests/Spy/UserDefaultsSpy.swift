//
//  UserDefaultsSpy.swift
//  PocketBase
//
//  Created by Brianna Zamora on 9/22/24.
//

import Foundation

public final class UserDefaultsSpy: UserDefaults {
    /// -initWithSuiteName: initializes an instance of NSUserDefaults that searches the shared preferences search list for the domain 'suitename'. For example, using the identifier of an application group will cause the receiver to search the preferences for that group. Passing the current application's bundle identifier, NSGlobalDomain, or the corresponding CFPreferences constants is an error. Passing nil will search the default search list.
    @available(iOS 7.0, *)
    override public init?(suiteName suitename: String?) {
        UserDefaults().removePersistentDomain(forName: suitename!)
        super.init(suiteName: suitename)
    }
    
    /**
     -objectForKey: will search the receiver's search list for a default with the key 'defaultName' and return it. If another process has changed defaults in the search list, NSUserDefaults will automatically update to the latest values. If the key in question has been marked as ubiquitous via a Defaults Configuration File, the latest value may not be immediately available, and the registered value will be returned instead.
     */
    override public func object(forKey defaultName: String) -> Any? {
        didCall_object_forKey += 1
        return super.object(forKey: defaultName)
    }
    public var didCall_object_forKey = 0
    
    /**
     -setObject:forKey: immediately stores a value (or removes the value if nil is passed as the value) for the provided key in the search list entry for the receiver's suite name in the current user and any host, then asynchronously stores the value persistently, where it is made available to other processes.
     */
    override public func set(_ value: Any?, forKey defaultName: String) {
        didCall_set_forKey += 1
        super.set(value, forKey: defaultName)
    }
    public var didCall_set_forKey = 0
    
    /// -removeObjectForKey: is equivalent to -[... setObject:nil forKey:defaultName]
    override public func removeObject(forKey defaultName: String) {
        didCall_removeObjectForKey += 1
        super.removeObject(forKey: defaultName)
    }
    public var didCall_removeObjectForKey = 0
    
    /// -stringForKey: is equivalent to -objectForKey:, except that it will convert NSNumber values to their NSString representation. If a non-string non-number value is found, nil will be returned.
    override public func string(forKey defaultName: String) -> String? {
        didCall_stringForKey += 1
        return super.string(forKey: defaultName)
    }
    public var didCall_stringForKey = 0
    
    /// -arrayForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray.
    override public func array(forKey defaultName: String) -> [Any]? {
        didCall_arrayForKey += 1
        return super.array(forKey: defaultName)
    }
    public var didCall_arrayForKey = 0
    
    /// -dictionaryForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSDictionary.
    override public func dictionary(forKey defaultName: String) -> [String : Any]? {
        didCall_dictionaryForKey += 1
        return super.dictionary(forKey: defaultName)
    }
    public var didCall_dictionaryForKey = 0
    
    /// -dataForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSData.
    override public func data(forKey defaultName: String) -> Data? {
        didCall_dataForKey += 1
        return super.data(forKey: defaultName)
    }
    public var didCall_dataForKey = 0
    
    /// -stringForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray<NSString *>. Note that unlike -stringForKey:, NSNumbers are not converted to NSStrings.
    override public func stringArray(forKey defaultName: String) -> [String]? {
        didCall_stringArrayForKey += 1
        return super.stringArray(forKey: defaultName)
    }
    public var didCall_stringArrayForKey = 0
    
    /**
     -integerForKey: is equivalent to -objectForKey:, except that it converts the returned value to an NSInteger. If the value is an NSNumber, the result of -integerValue will be returned. If the value is an NSString, it will be converted to NSInteger if possible. If the value is a boolean, it will be converted to either 1 for YES or 0 for NO. If the value is absent or can't be converted to an integer, 0 will be returned.
     */
    override public func integer(forKey defaultName: String) -> Int {
        didCall_integerForKey += 1
        return super.integer(forKey: defaultName)
    }
    public var didCall_integerForKey = 0
    
    /// -floatForKey: is similar to -integerForKey:, except that it returns a float, and boolean values will not be converted.
    override public func float(forKey defaultName: String) -> Float {
        didCall_floatForKey += 1
        return super.float(forKey: defaultName)
    }
    public var didCall_floatForKey = 0
    
    /// -doubleForKey: is similar to -integerForKey:, except that it returns a double, and boolean values will not be converted.
    override public func double(forKey defaultName: String) -> Double {
        didCall_doubleForKey += 1
        return super.double(forKey: defaultName)
    }
    public var didCall_doubleForKey = 0
    
    /**
     -boolForKey: is equivalent to -objectForKey:, except that it converts the returned value to a BOOL. If the value is an NSNumber, NO will be returned if the value is 0, YES otherwise. If the value is an NSString, values of "YES" or "1" will return YES, and values of "NO", "0", or any other string will return NO. If the value is absent or can't be converted to a BOOL, NO will be returned.
     
     */
    override public func bool(forKey defaultName: String) -> Bool {
        didCall_boolForKey += 1
        return super.bool(forKey: defaultName)
    }
    public var didCall_boolForKey = 0
    
    /**
     -URLForKey: is equivalent to -objectForKey: except that it converts the returned value to an NSURL. If the value is an NSString path, then it will construct a file URL to that path. If the value is an archived URL from -setURL:forKey: it will be unarchived. If the value is absent or can't be converted to an NSURL, nil will be returned.
     */
    @available(iOS 4.0, *)
    override public func url(forKey defaultName: String) -> URL? {
        didCall_urlForKey += 1
        return super.url(forKey: defaultName)
    }
    public var didCall_urlForKey = 0
    
    /// -setInteger:forKey: is equivalent to -setObject:forKey: except that the value is converted from an NSInteger to an NSNumber.
    override public func set(_ value: Int, forKey defaultName: String) {
        didCall_setIntegerForKey += 1
        super.set(value, forKey: defaultName)
    }
    public var didCall_setIntegerForKey: Int = 0
    
    /// -setFloat:forKey: is equivalent to -setObject:forKey: except that the value is converted from a float to an NSNumber.
    override public func set(_ value: Float, forKey defaultName: String) {
        didCall_setFloatForKey += 1
        super.set(value, forKey: defaultName)
    }
    public var didCall_setFloatForKey: Int = 0
    
    /// -setDouble:forKey: is equivalent to -setObject:forKey: except that the value is converted from a double to an NSNumber.
    override public func set(_ value: Double, forKey defaultName: String) {
        didCall_setDoubleForKey += 1
        super.set(value, forKey: defaultName)
    }
    public var didCall_setDoubleForKey: Int = 0
    
    /// -setBool:forKey: is equivalent to -setObject:forKey: except that the value is converted from a BOOL to an NSNumber.
    override public func set(_ value: Bool, forKey defaultName: String) {
        didCall_setBoolForKey += 1
        super.set(value, forKey: defaultName)
    }
    public var didCall_setBoolForKey: Int = 0
    
    /// -setURL:forKey is equivalent to -setObject:forKey: except that the value is archived to an NSData. Use -URLForKey: to retrieve values set this way.
    @available(iOS 4.0, *)
    override public func set(_ url: URL?, forKey defaultName: String) {
        didCall_setURLForKey += 1
        super.set(url, forKey: defaultName)
    }
    public var didCall_setURLForKey: Int = 0
    
    /**
     -registerDefaults: adds the registrationDictionary to the last item in every search list. This means that after NSUserDefaults has looked for a value in every other valid location, it will look in registered defaults, making them useful as a "fallback" value. Registered defaults are never stored between runs of an application, and are visible only to the application that registers them.
     
     Default values from Defaults Configuration Files will automatically be registered.
     */
    override public func register(defaults registrationDictionary: [String : Any]) {
        didCall_registerDefaults += 1
        super.register(defaults: registrationDictionary)
    }
    public var didCall_registerDefaults: Int = 0
    
    /**
     -addSuiteNamed: adds the full search list for 'suiteName' as a sub-search-list of the receiver's. The additional search lists are searched after the current domain, but before global defaults. Passing NSGlobalDomain or the current application's bundle identifier is unsupported.
     */
    override public func addSuite(named suiteName: String) {
        didCall_addSuiteNamed += 1
        super.addSuite(named: suiteName)
    }
    public var didCall_addSuiteNamed: Int = 0
    
    /**
     -removeSuiteNamed: removes a sub-searchlist added via -addSuiteNamed:.
     */
    override public func removeSuite(named suiteName: String) {
        didCall_removeSuiteNamed += 1
        super.removeSuite(named: suiteName)
    }
    public var didCall_removeSuiteNamed: Int = 0
    
    /**
     -dictionaryRepresentation returns a composite snapshot of the values in the receiver's search list, such that [[receiver dictionaryRepresentation] objectForKey:x] will return the same thing as [receiver objectForKey:x].
     */
    override public func dictionaryRepresentation() -> [String : Any] {
        didCall_dictionaryRepresentation += 1
        return super.dictionaryRepresentation()
    }
    public var didCall_dictionaryRepresentation: Int = 0
    
    override public var volatileDomainNames: [String] {
        didCall_volatileDomainNames += 1
        return super.volatileDomainNames
    }
    public var didCall_volatileDomainNames: Int = 0
    
    override public func volatileDomain(forName domainName: String) -> [String : Any] {
        didCall_volatileDomain_forName += 1
        return super.volatileDomain(forName: domainName)
    }
    public var didCall_volatileDomain_forName: Int = 0
    
    override public func setVolatileDomain(_ domain: [String : Any], forName domainName: String) {
        didCall_setVolatileDomain += 1
        super.setVolatileDomain(domain, forName: domainName)
    }
    public var didCall_setVolatileDomain: Int = 0
    
    override public func removeVolatileDomain(forName domainName: String) {
        didCall_removeVolatileDomain += 1
        super.removeVolatileDomain(forName: domainName)
    }
    public var didCall_removeVolatileDomain: Int = 0
    
    /// -persistentDomainForName: returns a dictionary representation of the search list entry specified by 'domainName', the current user, and any host.
    override public func persistentDomain(forName domainName: String) -> [String : Any]? {
        didCall_persistentDomainForName += 1
        return super.persistentDomain(forName: domainName)
    }
    public var didCall_persistentDomainForName: Int = 0
    
    /// -setPersistentDomain:forName: replaces all values in the search list entry specified by 'domainName', the current user, and any host, with the values in 'domain'. The change will be persisted.
    override public func setPersistentDomain(_ domain: [String : Any], forName domainName: String) {
        didCall_setPersistentDomain += 1
        super.setPersistentDomain(domain, forName: domainName)
    }
    public var didCall_setPersistentDomain: Int = 0
    
    /// -removePersistentDomainForName: removes all values from the search list entry specified by 'domainName', the current user, and any host. The change is persistent.
    override public func removePersistentDomain(forName domainName: String) {
        didCall_removePersistentDomain += 1
        super.removePersistentDomain(forName: domainName)
    }
    public var didCall_removePersistentDomain: Int = 0

    /**
     -synchronize is deprecated and will be marked with the API_DEPRECATED macro in a future release.
     
     -synchronize blocks the calling thread until all in-progress set operations have completed. This is no longer necessary. Replacements for previous uses of -synchronize depend on what the intent of calling synchronize was. If you synchronized...
     - ...before reading in order to fetch updated values: remove the synchronize call
     - ...after writing in order to notify another program to read: the other program can use KVO to observe the default without needing to notify
     - ...before exiting in a non-app (command line tool, agent, or daemon) process: call CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
     - ...for any other reason: remove the synchronize call
     */
    override public func synchronize() -> Bool {
        didCall_synchronize += 1
        return super.synchronize()
    }
    public var didCall_synchronize: Int = 0

    override public func objectIsForced(forKey key: String) -> Bool {
        didCall_objectIsForced += 1
        return super.objectIsForced(forKey: key)
    }
    public var didCall_objectIsForced: Int = 0

    override public func objectIsForced(forKey key: String, inDomain domain: String) -> Bool {
        didCall_objectIsForced_inDomain += 1
        return super.objectIsForced(forKey: key, inDomain: domain)
    }
    public var didCall_objectIsForced_inDomain: Int = 0
}
