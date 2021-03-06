package rt

import (
	"fmt"

	"github.com/jxwr/doubi/ast"
	"github.com/jxwr/doubi/env"
)

type Object interface {
	Dispatch(ctx *Runtime, method string, args ...Object) []Object
	Name() string
	String() string
	HashCode() string
}

type Property map[string]Object

func (self *Property) SetProp(key string, val Object) {
	(*self)[key] = val
}

func (self *Property) GetProp(key string) Object {
	return (*self)[key]
}

func (self *Property) AccessPropMethod(method string, args ...Object) (isPropMethod bool, results []Object) {
	if method == "__get_property__" {
		idx := args[0].(*StringObject)
		results = append(results, self.GetProp(idx.Val))
		isPropMethod = true
	} else if method == "__set_property__" {
		idx := args[0].(*StringObject)
		val := args[1]
		self.SetProp(idx.Val, val)
		isPropMethod = true
	}
	return
}

/// string

type StringObject struct {
	Property

	Val string
}

func NewStringObject(val string) Object {
	obj := &StringObject{Property(map[string]Object{}), val}
	return obj
}

func (self *StringObject) Name() string {
	return "string"
}

func (self *StringObject) HashCode() string {
	return self.String()
}

func (self *StringObject) String() string {
	return self.Val
}

func (self *StringObject) Dispatch(ctx *Runtime, method string, args ...Object) (results []Object) {
	var is bool
	if is, results = self.AccessPropMethod(method, args...); is {
		return
	}

	switch method {
	case "__add__":
		obj := NewStringObject(self.Val + args[0].String())
		results = append(results, obj)
	case "__+=__":
		self.Val += args[0].String()
	}
	return
}

/// bool

type BoolObject struct {
	Property

	Val bool
}

func NewBoolObject(val bool) Object {
	obj := &BoolObject{Property(map[string]Object{}), val}
	return obj
}

func (self *BoolObject) Name() string {
	return "bool"
}

func (self *BoolObject) HashCode() string {
	return self.String()
}

func (self *BoolObject) String() string {
	return fmt.Sprintf("%v", self.Val)
}

func (self *BoolObject) Dispatch(ctx *Runtime, method string, args ...Object) (results []Object) {
	var is bool
	if is, results = self.AccessPropMethod(method, args...); is {
		return
	}

	val := args[0].(*BoolObject).Val
	switch method {
	case "__land__":
		val = self.Val && val
	case "__lor__":
		val = self.Val || val
	case "__not__":
		val = !self.Val
	}

	results = append(results, NewBoolObject(val))
	return
}

/// integer

type IntegerObject struct {
	Property

	Val int
}

func NewIntegerObject(val int) Object {
	obj := &IntegerObject{Property(map[string]Object{}), val}
	obj.SetProp("times", NewBuiltinFuncObject("times", obj, nil))
	obj.SetProp("abs", NewBuiltinFuncObject("abs", obj, nil))
	return obj
}

func (self *IntegerObject) Name() string {
	return "integer"
}

func (self *IntegerObject) HashCode() string {
	return self.String()
}

func (self *IntegerObject) String() string {
	return fmt.Sprintf("%d", self.Val)
}

func (self *IntegerObject) classMethods(ctx *Runtime, method string, args ...Object) (results []Object) {
	switch method {
	case "times":
		fnobj := args[0].(*FuncObject)
		fnDecl := fnobj.Decl
		for i := 0; i < self.Val; i++ {
			fnobj.E.Put(fnDecl.Args[0].Name, NewIntegerObject(i))
			fnDecl.Body.Accept(ctx.Visitor)
		}
	case "abs":
		val := self.Val
		if val < 0 {
			val = 0 - val
		}
		results = append(results, NewIntegerObject(val))
	}
	return
}

// shits
func (self *IntegerObject) Dispatch(ctx *Runtime, method string, args ...Object) (results []Object) {
	var is bool
	if is, results = self.AccessPropMethod(method, args...); is {
		return
	}

	isFloat := false
	var val float64

	if len(args) == 0 {
		if method == "__inc__" {
			self.Val++
		} else if method == "__dec__" {
			self.Val--
		} else {
			results = self.classMethods(ctx, method, args...)
			return
		}
		return
	}

	switch arg := args[0].(type) {
	case *IntegerObject:
		val = float64(arg.Val)
	case *FloatObject:
		isFloat = true
		val = arg.Val
	}

	switch method {
	// xxx_assign
	case "__+=__":
		self.Val += int(val)
		return
	case "__-=__":
		self.Val -= int(val)
		return
	case "__*=__":
		self.Val *= int(val)
		return
	case "__/=__":
		self.Val /= int(val)
		return
	case "__%=__":
		self.Val %= int(val)
		return
	case "__|=__":
		self.Val |= int(val)
		return
	case "__&=__":
		self.Val &= int(val)
		return
	case "__^=__":
		self.Val ^= int(val)
		return
	case "__<<=__":
		self.Val <<= uint(val)
		return
	case "__>>=__":
		self.Val >>= uint(val)
		return
	case "__&^___":
		self.Val &^= int(val)
		return
	// binop
	case "__add__":
		val = float64(self.Val) + val
	case "__sub__":
		val = float64(self.Val) - val
	case "__mul__":
		val = float64(self.Val) * val
	case "__quo__":
		val = float64(self.Val) / val
	case "__rem__":
		val = float64(self.Val % int(val))
	case "__and__":
		val = float64(self.Val & int(val))
	case "__or__":
		val = float64(self.Val | int(val))
	case "__xor__":
		val = float64(self.Val ^ int(val))
	case "__shl__":
		val = float64(uint(self.Val) << uint(val))
	case "__shr__":
		val = float64(uint(self.Val) >> uint(val))
	case "__eql__":
		cmp := float64(self.Val) == val
		results = append(results, NewBoolObject(cmp))
		return
	case "__lss__":
		cmp := float64(self.Val) < val
		results = append(results, NewBoolObject(cmp))
		return
	case "__gtr__":
		cmp := float64(self.Val) > val
		results = append(results, NewBoolObject(cmp))
		return
	case "__leq__":
		cmp := float64(self.Val) <= val
		results = append(results, NewBoolObject(cmp))
		return
	case "__geq__":
		cmp := float64(self.Val) >= val
		results = append(results, NewBoolObject(cmp))
		return
	case "__neq__":
		cmp := float64(self.Val) != val
		results = append(results, NewBoolObject(cmp))
		return
	default:
		results = self.classMethods(ctx, method, args...)
		return
	}

	if isFloat {
		results = append(results, NewFloatObject(val))
	} else {
		results = append(results, NewIntegerObject(int(val)))
	}
	return
}

/// float

type FloatObject struct {
	Property

	Val float64
}

func NewFloatObject(val float64) Object {
	obj := &FloatObject{Property(map[string]Object{}), val}
	return obj
}

func (self *FloatObject) HashCode() string {
	return self.String()
}

func (self *FloatObject) Name() string {
	return "float"
}

func (self *FloatObject) String() string {
	return fmt.Sprintf("%f", self.Val)
}

func (self *FloatObject) Dispatch(ctx *Runtime, method string, args ...Object) (results []Object) {
	var is bool
	if is, results = self.AccessPropMethod(method, args...); is {
		return
	}

	var val float64

	switch arg := args[0].(type) {
	case *IntegerObject:
		val = float64(arg.Val)
	case *FloatObject:
		val = arg.Val
	}

	switch method {
	case "__+=__":
		self.Val += val
		return
	case "__-=__":
		self.Val -= val
		return
	case "__*=__":
		self.Val *= val
		return
	case "__/=__":
		self.Val /= val
		return
	case "__add__":
		val = self.Val + val
	case "__sub__":
		val = self.Val - val
	case "__mul__":
		val = self.Val * val
	case "__quo__":
		val = self.Val / val
	case "__eql__":
		cmp := self.Val == val
		results = append(results, NewBoolObject(cmp))
		return
	case "__lss__":
		cmp := self.Val < val
		results = append(results, NewBoolObject(cmp))
		return
	case "__gtr__":
		cmp := self.Val > val
		results = append(results, NewBoolObject(cmp))
		return
	case "__leq__":
		cmp := self.Val <= val
		results = append(results, NewBoolObject(cmp))
		return
	case "__geq__":
		cmp := self.Val >= val
		results = append(results, NewBoolObject(cmp))
		return
	case "__neq__":
		cmp := self.Val != val
		results = append(results, NewBoolObject(cmp))
		return
	}
	results = append(results, NewFloatObject(val))
	return
}

/// array

type ArrayObject struct {
	Property

	Vals []Object
}

func NewArrayObject(vals []Object) Object {
	obj := &ArrayObject{Property(map[string]Object{}), vals}
	obj.SetProp("append", NewBuiltinFuncObject("append", obj, nil))
	obj.SetProp("length", NewBuiltinFuncObject("length", obj, nil))

	return obj
}

func (self *ArrayObject) Name() string {
	return "array"
}

func (self *ArrayObject) HashCode() string {
	return fmt.Sprintf("%p", self)
}

func (self *ArrayObject) String() string {
	s := "["
	ln := len(self.Vals)
	for i, val := range self.Vals {
		s += val.String()
		if i < ln-1 {
			s += ","
		}
	}
	s += "]"
	return s
}

func (self *ArrayObject) Dispatch(ctx *Runtime, method string, args ...Object) (results []Object) {
	var is bool
	if is, results = self.AccessPropMethod(method, args...); is {
		return
	}

	switch method {
	case "__add__":
		vals := append(self.Vals[:], args[0].(*ArrayObject).Vals...)
		ret := NewArrayObject(vals)
		results = append(results, ret)
	case "__+=__":
		self.Vals = append(self.Vals, args[0].(*ArrayObject).Vals...)
	case "__get_index__":
		idx := args[0].(*IntegerObject)
		obj := self.Vals[idx.Val]
		results = append(results, obj)
	case "__set_index__":
		idx := args[0].(*IntegerObject)
		val := args[1]
		self.Vals[idx.Val] = val
	case "__slice__":
		low := 0
		high := len(self.Vals)

		lo := args[0]
		if lo != nil {
			low = lo.(*IntegerObject).Val
		}
		ho := args[1]
		if ho != nil {
			high = ho.(*IntegerObject).Val
		}

		vals := self.Vals[low:high]
		ret := NewArrayObject(vals)
		results = append(results, ret)
	case "append":
		val := args[0]
		self.Vals = append(self.Vals, val)
	case "length":
		ret := NewIntegerObject(len(self.Vals))
		results = append(results, ret)
	}
	return
}

/// set

type SetObject struct {
	Property

	Vals []Object
}

func NewSetObject(vals []Object) Object {
	obj := &SetObject{Property(map[string]Object{}), vals}
	return obj
}

func (self *SetObject) Name() string {
	return "set"
}

func (self *SetObject) HashCode() string {
	return fmt.Sprintf("%p", self)
}

func (self *SetObject) String() string {
	s := "#["
	ln := len(self.Vals)
	for i, val := range self.Vals {
		s += val.String()
		if i < ln-1 {
			s += ","
		}
	}
	s += "]"
	return s
}

func (self *SetObject) Dispatch(ctx *Runtime, method string, args ...Object) (results []Object) {
	var is bool
	if is, results = self.AccessPropMethod(method, args...); is {
		return
	}

	switch method {
	case "__add__":
		fmt.Println("__add__")
	}
	return
}

/// function

type FuncObject struct {
	Property

	name string
	Decl *ast.FuncDeclExpr

	IsBuiltin bool
	Obj       Object
	E         *env.Env
}

func NewFuncObject(name string, decl *ast.FuncDeclExpr, e *env.Env) Object {
	obj := &FuncObject{Property(map[string]Object{}), name, decl, false, nil, e}
	return obj
}

func NewBuiltinFuncObject(name string, recv Object, e *env.Env) Object {
	obj := &FuncObject{Property(map[string]Object{}), name, nil, true, recv, e}
	return obj
}

func (self *FuncObject) Name() string {
	return "function"
}

func (self *FuncObject) HashCode() string {
	return fmt.Sprintf("%p", self)
}

func (self *FuncObject) String() string {
	return self.name
}

var Builtins = map[string]func(args ...Object) []Object{
	"print": func(args ...Object) (results []Object) {
		ifs := []interface{}{}
		for _, arg := range args {
			ifs = append(ifs, arg)
		}
		fmt.Print(ifs...)
		return
	},
}

func (self *FuncObject) Dispatch(ctx *Runtime, method string, args ...Object) (results []Object) {
	var is bool
	if is, results = self.AccessPropMethod(method, args...); is {
		return
	}

	switch method {
	case "__call__":
		if self.Decl == nil && self.Obj == nil {
			fn, ok := Builtins[self.name]
			if ok {
				results = fn(args...)
			}
		} else {
			results = self.Obj.Dispatch(ctx, self.name, args...)
		}
	}
	return
}

/// dict

type DictObject struct {
	Property
}

func NewDictObject(fields *map[string]Object) Object {
	obj := &DictObject{Property(*fields)}

	return obj
}

func (self *DictObject) Name() string {
	return "dict"
}

func (self *DictObject) HashCode() string {
	return fmt.Sprintf("%p", self)
}

func (self *DictObject) String() string {
	s := "#{"

	ln := len(self.Property)
	idx := 0
	for key, val := range self.Property {
		s += key
		s += ":"
		s += val.String()
		if idx < ln-1 {
			s += ","
		}
		idx++
	}
	s += "}"
	return s
}

func (self *DictObject) Dispatch(ctx *Runtime, method string, args ...Object) (results []Object) {
	var is bool
	if is, results = self.AccessPropMethod(method, args...); is {
		return
	}

	switch method {
	case "__get_index__":
		idx := args[0]
		results = append(results, self.GetProp(idx.HashCode()))
	case "__set_index__":
		idx := args[0]
		val := args[1]
		self.SetProp(idx.HashCode(), val)
	}
	return
}
