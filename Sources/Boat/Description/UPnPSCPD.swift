struct SCPD {
    // TODO: Handle xmlns attribute

    let specVersion: Version

    struct Action {
        let name: String

        struct Argument: Decodable {
            let name: String
            let direction: String
            let relatedStateVariable: String
        }
        let arguments: [Argument]?
    }
    let actions: [String: Action]

    // TODO: sendEvents attribute
    struct StateVariable {
        let name: String

        enum Value {
            case boolean(Bool)
            case number(UInt)
            case text(String)
            case unsupported
        }

        let defaultValue: Value?
        let allowedValues: [String]?
        let allowedRange: ClosedRange<Int>?
    }
    let stateVariables: [String: StateVariable]
}

extension SCPD.Action: Decodable {
    init(from decoder: Decoder) throws {
        let action = try decoder.container(keyedBy: DynamicKey.self)
        name = try action.decode(String.self, forKey: "name")

        do {
            let argumentList = try action.nestedContainer(
                keyedBy: DynamicKey.self,
                forKey: "argumentList"
            )
            arguments = try argumentList.decode([Argument].self, forKey: "argument")
        } catch DecodingError.keyNotFound {
            arguments = nil
        }
    }
}

extension SCPD.StateVariable: Decodable {
    enum CodingKeys: CodingKey {
        case name
        case dataType
        case defaultValue
        case allowedValueList
        case allowedValueRange
    }

    init(from decoder: Decoder) throws {
        let stateVariable = try decoder.container(keyedBy: CodingKeys.self)
        name = try stateVariable.decode(String.self, forKey: .name)

        let type = try stateVariable.decode(String.self, forKey: .dataType)
        do {
            switch type {
            case "boolean":
                let value = try stateVariable.decode(Bool.self, forKey: .defaultValue)
                defaultValue = .boolean(value)
            case "ui2", "ui4":
                let value = try stateVariable.decode(UInt.self, forKey: .defaultValue)
                defaultValue = .number(value)
            case "string":
                let value = try stateVariable.decode(String.self, forKey: .defaultValue)
                defaultValue = .text(value)
            default:
                defaultValue = .unsupported
            }
        } catch DecodingError.keyNotFound {
            defaultValue = nil
        }

        do {
            let allowedValueList = try stateVariable.nestedContainer(
                keyedBy: DynamicKey.self,
                forKey: .allowedValueList
            )
            allowedValues = try allowedValueList.decode([String].self, forKey: "allowedValue")
        } catch DecodingError.keyNotFound {
            allowedValues = nil
        }

        do {
            let allowedValueRange = try stateVariable.nestedContainer(
                keyedBy: DynamicKey.self,
                forKey: .allowedValueRange
            )
            let min = try allowedValueRange.decode(Int.self, forKey: "minimum")
            let max = try allowedValueRange.decode(Int.self, forKey: "maximum")
            allowedRange = min...max
        } catch DecodingError.keyNotFound {
            allowedRange = nil
        }
    }
}

extension SCPD: Decodable {
    enum CodingKeys: CodingKey {
        case specVersion
        case actionList
        case serviceStateTable
    }

    init(from decoder: Decoder) throws {
        let scpd = try decoder.container(keyedBy: CodingKeys.self)

        // Init specification version
        specVersion = try scpd.decode(Version.self, forKey: .specVersion)

        // Init action list
        let actionList = try scpd.nestedContainer(
            keyedBy: DynamicKey.self,
            forKey: .actionList
        )
        let actions = try actionList.decode([Action].self, forKey: "action")
        var actionDict = [String: Action]()
        for action in actions {
            actionDict[action.name] = action
        }
        self.actions = actionDict

        // Init state variable list
        let serviceStateTable = try scpd.nestedContainer(
            keyedBy: DynamicKey.self,
            forKey: .serviceStateTable
        )
        let stateVariables = try serviceStateTable.decode(
            [StateVariable].self,
            forKey: "stateVariable"
        )
        var stateDict = [String: StateVariable]()
        for variable in stateVariables {
            stateDict[variable.name] = variable
        }
        self.stateVariables = stateDict
    }
}
