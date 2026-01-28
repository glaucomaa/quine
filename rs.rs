fn main() {
    let s = "fn main() {\n    let s = {S};\n    let out = s.replacen(\"{S}\", &format!(\"{:?}\", s), 1);\n    print!(\"{}\", out);\n}\n";
    let out = s.replacen("{S}", &format!("{:?}", s), 1);
    print!("{}", out);
}
