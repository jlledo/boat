import Darwin.sys.sysctl
import Version

enum SysctlWrapper {
    /// CTL_KERN identifiers
    private enum CtlKernelName: Int32 {
        /// KERN_OSTYPE
        case osType = 1
        /// KERN_OSRELEASE
        case osRelease = 2
    }

    private static func getKernelString(_ name: CtlKernelName) -> String {
        // Management Information Base style names
        var mibNames: [Int32] = [CTL_KERN, name.rawValue]

        // Retrieve rquired buffer size
        var bufferSize: Int = 0
        sysctl(&mibNames, UInt32(mibNames.count), nil, &bufferSize, nil, 0)

        // Retrieve kernel string
        var string = [CChar](repeating: 0, count: bufferSize)
        sysctl(&mibNames, UInt32(mibNames.count), &string, &bufferSize, nil, 0)

        return String(cString: &string)
    }

    /// System version (e.g. Darwin)
    static var osType: String { getKernelString(.osType) }

    /// System release (e.g. 19.0.0)
    static var osRelease: Version { Version(getKernelString(.osRelease))! }
}
