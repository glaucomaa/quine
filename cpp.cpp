#include <iostream>
#include <string>
#include <string_view>
#include <cstddef>

static std::string escape_cpp(std::string_view in) {
    static constexpr char hex[] = "0123456789ABCDEF";
    std::string out;
    out.reserve(in.size() * 2);

    for (unsigned char c : in) {
        switch (c) {
            case '\\': out += "\\\\"; break;
            case '"':  out += "\\\""; break;
            case '\n': out += "\\n"; break;
            case '\t': out += "\\t"; break;
            case '\r': out += "\\r"; break;
            default:
                if (c < 0x20) {
                    out += "\\x";
                    out.push_back(hex[(c >> 4) & 0xF]);
                    out.push_back(hex[c & 0xF]);
                } else {
                    out.push_back(static_cast<char>(c));
                }
        }
    }
    return out;
}

static void render(std::string_view t) {
    for (std::size_t i = 0; i < t.size();) {
        if (i + 2 < t.size() && t[i] == '@' && t[i + 1] == 'Q' && t[i + 2] == '@') {
            std::cout << '"';
            i += 3;
        } else if (i + 2 < t.size() && t[i] == '@' && t[i + 1] == 'S' && t[i + 2] == '@') {
            std::cout << escape_cpp(t);
            i += 3;
        } else {
            std::cout << t[i++];
        }
    }
}

int main() {
    const std::string t = "#include <iostream>\n#include <string>\n#include <string_view>\n#include <cstddef>\n\nstatic std::string escape_cpp(std::string_view in) {\n    static constexpr char hex[] = \"0123456789ABCDEF\";\n    std::string out;\n    out.reserve(in.size() * 2);\n\n    for (unsigned char c : in) {\n        switch (c) {\n            case '\\\\': out += \"\\\\\\\\\"; break;\n            case '\"':  out += \"\\\\\\\"\"; break;\n            case '\\n': out += \"\\\\n\"; break;\n            case '\\t': out += \"\\\\t\"; break;\n            case '\\r': out += \"\\\\r\"; break;\n            default:\n                if (c < 0x20) {\n                    out += \"\\\\x\";\n                    out.push_back(hex[(c >> 4) & 0xF]);\n                    out.push_back(hex[c & 0xF]);\n                } else {\n                    out.push_back(static_cast<char>(c));\n                }\n        }\n    }\n    return out;\n}\n\nstatic void render(std::string_view t) {\n    for (std::size_t i = 0; i < t.size();) {\n        if (i + 2 < t.size() && t[i] == '@' && t[i + 1] == 'Q' && t[i + 2] == '@') {\n            std::cout << '\"';\n            i += 3;\n        } else if (i + 2 < t.size() && t[i] == '@' && t[i + 1] == 'S' && t[i + 2] == '@') {\n            std::cout << escape_cpp(t);\n            i += 3;\n        } else {\n            std::cout << t[i++];\n        }\n    }\n}\n\nint main() {\n    const std::string t = @Q@@S@@Q@;\n    render(t);\n    return 0;\n}\n";
    render(t);
    return 0;
}
