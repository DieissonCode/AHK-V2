#Requires AutoHotkey v2.0

class A extends b {
    metodoA() => MsgBox("A")
}

class B extends C {
    metodoB() => MsgBox("B")
}

class C {
    metodoC() => MsgBox("C")
}

class X extends A {
    __New() {
        
    }
}

obj := X()
obj.metodoA()
obj.metodoB()
obj.metodoC()
