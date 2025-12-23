import JavaScriptKit
import KvParser

public struct KvSyntaxHighlight {
    public static func register() {
        let monaco = JSObject.global.monaco
        guard let languages = monaco.languages.object else {
            print("Monaco languages API not available")
            return
        }
        
        // Register the KV language
        let langDef: [String: JSValue] = [
            "id": "kv".jsValue,
            "extensions": [".kv"].jsValue,
            "aliases": ["KV", "kv", "Kivy"].jsValue
        ]
        _ = languages.register!(langDef.jsValue)
        
        // Create tokenization provider using KvParser's tokenizer
        let tokenProvider = JSObject()
        
        tokenProvider.getInitialState = .object(JSClosure { _ in
            let state = JSObject()
            // Monaco requires state objects to have clone() and equals() methods
            state.clone = .object(JSClosure { _ in
                let clonedState = JSObject()
                clonedState.clone = state.clone
                clonedState.equals = state.equals
                return clonedState.jsValue
            })
            state.equals = .object(JSClosure { args in
                // Simple stateless tokenizer - all states are equal
                return JSValue.boolean(true)
            })
            return state.jsValue
        })
        
        tokenProvider.tokenize = .object(JSClosure { args -> JSValue in
            guard args.count >= 2,
                  let line = args[0].string else {
                let result = JSObject()
                result.tokens = ([JSValue]()).jsValue
                result.endState = JSObject().jsValue
                result.endState.clone = .object(JSClosure { _ in
                    let clonedState = JSObject()
                    clonedState.clone = result.endState.clone
                    clonedState.equals = result.endState.equals
                    return clonedState.jsValue
                })
                result.endState.equals = JSClosure { _ in
                    return JSValue.boolean(true)
                }.jsValue
                return result.jsValue
            }
            
            // Get the state parameter (args[1])
            let state = args[1]
            
            // Use KvTokenizer to parse the line
            let tokenizer = KvTokenizer(source: line)
            let kvTokens: [Token]
            do {
                kvTokens = try tokenizer.tokenize()
            } catch {
                // Fallback on error - return empty tokens with state
                let result = JSObject()
                result.tokens = ([JSValue]()).jsValue
                result.endState = state
                return result.jsValue
            }
            
            // Convert KvTokens to Monaco tokens
            var monacoTokens: [[String: JSValue]] = []
            
            // Filter out structural tokens first
            let relevantTokens = kvTokens.filter { token in
                switch token.type {
                case .indent, .dedent, .newline, .eof:
                    return false
                default:
                    return true
                }
            }
            
            // Convert byte positions to character positions
            let characterPositions = relevantTokens.map { token -> Int in
                // Token.column is 1-based, convert to 0-based character index
                let byteOffset = token.column - 1
                guard byteOffset >= 0 else { return 0 }
                
                // Count UTF-16 code units up to this byte position
                var currentByte = 0
                var charIndex = 0
                
                for char in line {
                    if currentByte >= byteOffset {
                        break
                    }
                    currentByte += char.utf8.count
                    charIndex += char.utf16.count
                }
                
                return charIndex
            }
            
            for (index, kvToken) in relevantTokens.enumerated() {
                // Check if this identifier is followed by a colon (property definition)
                let isProperty: Bool
                if case .identifier(let name) = kvToken.type,
                   !name.hasPrefix("on_"),
                   name.first?.isLowercase == true,
                   index + 1 < relevantTokens.count,
                   case .colon = relevantTokens[index + 1].type {
                    isProperty = true
                } else {
                    isProperty = false
                }
                
                monacoTokens.append([
                    "startIndex": Double(characterPositions[index]).jsValue,
                    "scopes": mapTokenType(kvToken.type, isProperty: isProperty).jsValue
                ])
            }
            
            // Return result object with tokens and endState
            let result = JSObject()
            result.tokens = monacoTokens.jsValue
            result.endState = state
            return result.jsValue
        })
        
        _ = languages.setTokensProvider!("kv", tokenProvider.jsValue)
        
        // Set language configuration
        let config = JSObject()
        
        // Comments
        let comments = JSObject()
        comments.lineComment = .string("#")
        config.comments = comments.jsValue
        
        // Brackets - pairs of matching brackets
        config.brackets = [
            ["[", "]"],
            ["(", ")"],
            ["{", "}"],
            ["<", ">"]
        ].jsValue
        
        // Auto-closing pairs
        let pairs: [[String: String]] = [
            ["open": "[", "close": "]"],
            ["open": "(", "close": ")"],
            ["open": "{", "close": "}"],
            ["open": "\"", "close": "\""],
            ["open": "'", "close": "'"]
        ]
        config.autoClosingPairs = pairs.jsValue
        config.surroundingPairs = pairs.jsValue
        
        _ = languages.setLanguageConfiguration!("kv", config.jsValue)
        
        print("✅ KV language registered with Monaco (using KvParser tokenizer)")
    }
    
    // Map KvParser token types to Monaco token classes
    private static func mapTokenType(_ tokenType: TokenType, isProperty: Bool = false) -> String {
        switch tokenType {
        case .identifier(let name):
            // Property names (yellow/gold color)
            if isProperty {
                return "attribute.name"
            }
            // Widget class names start with uppercase
            if name.first?.isUppercase == true {
                return "type.identifier"
            }
            // Event handlers
            if name.hasPrefix("on_") {
                return "keyword.control"
            }
            return "identifier"
            
        case .string:
            return "string"
            
        case .number:
            return "number"
            
        case .colon:
            return "delimiter"
            
        case .comma:
            return "delimiter.comma"
            
        case .leftAngle, .rightAngle:
            return "keyword.control"
            
        case .leftBracket, .rightBracket:
            return "delimiter.bracket"
            
        case .leftParen, .rightParen:
            return "delimiter.parenthesis"
            
        case .dot:
            return "delimiter"
            
        case .minus, .at, .plus:
            return "operator"
            
        case .canvas, .canvasBefore, .canvasAfter:
            return "keyword"
            
        case .directive:
            return "keyword.directive"
            
        case .comment:
            return "comment"
            
        default:
            return ""
        }
    }
}
