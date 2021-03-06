Attribute VB_Name = "SQLUnitTests"
Public Function SQL_RunUnitTests()
    Dim Interfaced As iSQLQuery
    
    '*****************Check Create*****************
    'Dim MyCreate As SQLCreate
    'Set MyCreate = Create_SQLCreate
    'With MyCreate
    '    .Table = "users"
    '    .Fields = Array(Array("id", "int"), Array("username", "varchar", 50))
    'End With
    'Dim Interfaced As iSQLQuery
    'Set Interfaced = MyCreate
    'CheckSQLValue Interfaced, "CREATE TABLE users (id int, username varchar(50))"
    
    '*****************Check Database*******************************************
    Dim MyDatabase As SQLDatabase
    Set MyDatabase = Create_SQLDatabase()
    Dim MyRecordset As New SQLTestRecordset
    Dim MyConnection As New SQLTestConnection
    With MyDatabase
        .DSN = "mydsn"
        .DBType = "mssql"
        .Password = "Pa$$word"
        .Username = "myusername"
        Set .Recordset = MyRecordset
        Set .Connection = MyConnection
    End With
    
    Dim SimpleInsert As SQLInsert
    Set SimpleInsert = Create_SQLInsert
    With SimpleInsert
        .Table = "users"
        .Fields = Array("id")
        .Values = Array(1)
    End With
    CheckPrimativeValue MyDatabase.InsertGetNewId(SimpleInsert), "SET NOCOUNT ON;INSERT INTO users (id) VALUES (1);SELECT SCOPE_IDENTITY() as somethingunique"
    
    MyDatabase.DBType = "psql"
    CheckPrimativeValue MyDatabase.InsertGetNewId(SimpleInsert, "id"), "INSERT INTO users (id) VALUES (1) RETURNING id"
    
    '******************************Check Delete********************************
    Dim MyDelete As SQLDelete
    Set MyDelete = Create_SQLDelete()
    MyDelete.Table = "users"
    
    Set Interfaced = MyDelete
    CheckSQLValue Interfaced, "DELETE FROM users"
    
    MyDelete.AddWhere "age", ":age", "<"
    MyDelete.AddArgument ":age", 13
    CheckSQLValue Interfaced, "DELETE FROM users WHERE age<13"
    
    '*********************Check Insert*****************************************
    Dim MyInsert As SQLInsert
    Set MyInsert = Create_SQLInsert
    MyInsert.Table = "users"
    MyInsert.Fields = Array("name", "type")
    MyInsert.Values = Array("'foo'", "'admin'")
    MyInsert.Returning = "id"
    Set Interfaced = MyInsert
    CheckSQLValue Interfaced, "INSERT INTO users (name, type) VALUES ('foo', 'admin') RETURNING id"
    
    Dim MySelect As SQLSelect
    Set MySelect = Create_SQLSelect
    With MySelect
        .Table = "account_types"
        .Fields = Array("'foo'", "id")
        .AddWhere "type", ":type"
        .AddArgument ":type", "admin"
    End With
    With MyInsert
        .Fields = Array("name", "type_id")
        .Values = Array()
        Set .From = MySelect
    End With
    CheckSQLValue Interfaced, "INSERT INTO users (name, type_id) (SELECT 'foo', id FROM account_types WHERE type='admin') RETURNING id"
    
    'Insert Multiple Values
    Set MyInsert = Create_SQLInsert
    MyInsert.Table = "users"
    MyInsert.Fields = Array("name", "type")
    Dim Values(1) As Variant
    
    Values(0) = Array("'foo'", "'admin'")
    Values(1) = Array("'bar'", "'editor'")
    MyInsert.Values = Values
    Set Interfaced = MyInsert
    CheckSQLValue Interfaced, "INSERT INTO users (name, type) VALUES ('foo', 'admin'), ('bar', 'editor')"
    '*******************Check Recordset****************************************
    
    
    '*******************Check Select*******************************************
    Set MySelect = Create_SQLSelect
    MySelect.Table = "users"
    MySelect.Fields = Array("id", "username")
    MySelect.AddWhere "created", "'2000-01-01'", ">"
    Set Interfaced = MySelect
    CheckSQLValue Interfaced, "SELECT id, username FROM users WHERE created>'2000-01-01'"
    
    MySelect.AddWhere "type", "'admin'"
    CheckSQLValue Interfaced, "SELECT id, username FROM users WHERE created>'2000-01-01' AND type='admin'"
    
    MySelect.AddWhere "flag", "NULL", "IS", "OR"
    CheckSQLValue Interfaced, "SELECT id, username FROM users WHERE (created>'2000-01-01' AND type='admin') OR flag IS NULL"

    Dim MyOtherSelect As SQLSelect
    Set MyOtherSelect = Create_SQLSelect
    MyOtherSelect.getByProperty "users", "id", "name", ":name"
    MyOtherSelect.AddArgument ":name", "admin"
    Set Interfaced = MyOtherSelect
    CheckSQLValue Interfaced, "SELECT id FROM users WHERE name='admin'"
    
    'Check Join
    Set MySelect = Create_SQLSelect
    With MySelect
        .addTable "users", "u"
        .InnerJoin "countries", "c", "u.country=c.country"
        .Fields = Array("u.uname", "c.capital")
    End With
    Set Interfaced = MySelect
    CheckSQLValue Interfaced, "SELECT u.uname, c.capital FROM users u INNER JOIN countries c ON u.country=c.country"
    
    MySelect.AddField "t.zone"
    MySelect.InnerJoin "timezones", "t", "c.capital=t.city"
    CheckSQLValue Interfaced, "SELECT u.uname, c.capital, t.zone FROM users u INNER JOIN countries c ON u.country=c.country INNER JOIN timezones t ON c.capital=t.city"
    
    'Distinct
    Set MySelect = Create_SQLSelect
    With MySelect
        .addTable "customers", "c"
        .Fields = Array("c.country")
        .Distinct
        .OrderBy ("c.country")
    End With
    Set Interfaced = MySelect
    CheckSQLValue Interfaced, "SELECT DISTINCT c.country FROM customers c ORDER BY c.country ASC"
    
    '*******************Check Static****************************************
    Dim MyStatic As SQLStaticQuery
    Set MyStatic = Create_SQLStaticQuery
    MyStatic.Query = "DELETE FROM users"
    Set Interfaced = MyStatic
    CheckSQLValue Interfaced, "DELETE FROM users"
    
    'Name missing ":"
    MyStatic.Query = "SELECT name FROM users WHERE id=:id"
    MyStatic.AddArgument "id", 4
    CheckSQLValue Interfaced, "SELECT name FROM users WHERE id=:id"
    
    'Proper function
    MyStatic.AddArgument ":id", 4
    CheckSQLValue Interfaced, "SELECT name FROM users WHERE id=4"
    
    'Can Change value
    MyStatic.AddArgument ":id", 40
    CheckSQLValue Interfaced, "SELECT name FROM users WHERE id=40"
    
    'Text is escaped
    MyStatic.AddArgument ":id", "text"
    CheckSQLValue Interfaced, "SELECT name FROM users WHERE id='text'"
    
    'Multiple arguments
    MyStatic.Query = "SELECT name FROM users WHERE id=:id AND type=:type"
    MyStatic.ClearArguments
    MyStatic.AddArgument ":type", "admin"
    CheckSQLValue Interfaced, "SELECT name FROM users WHERE id=:id AND type='admin'"
    MyStatic.ClearArguments
    MyStatic.AddArgument ":id", 4
    CheckSQLValue Interfaced, "SELECT name FROM users WHERE id=4 AND type=:type"
    
    MyStatic.AddArgument ":type", "admin"
    CheckSQLValue Interfaced, "SELECT name FROM users WHERE id=4 AND type='admin'"
    
    'Can not place an argument in a value
    MyStatic.AddArgument ":id", "4:type"
    MyStatic.AddArgument ":type", ";DELETE FROM users;:id"
    CheckSQLValue Interfaced, "SELECT name FROM users WHERE id='4:type' AND type=';DELETE FROM users;:id'"
    '*******************Check SubSelect****************************************
    'Dim MySubselect As New SQLSubselect
    'Set MySubselect.SelectSQL = MyOtherSelect
    'MySubselect.SelectAs = "user_id"
    'CheckSQLValue MySubselect, "(SELECT id FROM users WHERE name='admin') AS user_id"
    
    '******************************Check Update********************************
    Dim MyUpdate As SQLUpdate
    Set MyUpdate = Create_SQLUpdate
    With MyUpdate
        .Table = "users"
        .Fields = Array("username")
        .Values = Array(str("admin' WHERE id=1;DROP TABLE users;"))
        .AddWhere "id", 1
    End With
    Set Interfaced = MyUpdate
    CheckSQLValue Interfaced, "UPDATE users SET username='admin'' WHERE id=1;DROP TABLE users;' WHERE id=1"
    
    '****************Check Where Group*****************************************
    'Dim MyWhereGroup As New SQLWhereGroup
    'Dim MyOtherWhere As New SQLCondition
    'MyOtherWhere.Create "type", "'toys'"
    'MyWhereGroup.SetGroup MyWhere, MyOtherWhere, "AND"
    'CheckSQLValue MyWhereGroup, "id=2 AND type='toys'"
    
    'Dim MyThirdWhere As New SQLCondition
    'MyThirdWhere.Create "color", "'pink'"
    
    'MyWhereGroup.AddWhere MyThirdWhere, "OR"
    'CheckSQLValue MyWhereGroup, "(id=2 AND type='toys') OR color='pink'"
    
    'Dim MyOtherWhereGroup As New SQLWhereGroup
    'MyOtherWhereGroup.SetGroup MyWhere, MyThirdWhere, "OR"
    'MyWhereGroup.AddWhere MyOtherWhereGroup, "AND"
    'CheckSQLValue MyWhereGroup, "((id=2 AND type='toys') OR color='pink') AND (id=2 OR color='pink')"

End Function

Function CheckSQLValue(MyObject As iSQLQuery, ExpectedValue)
    If MyObject.toString <> ExpectedValue Then
        MsgBox "Expected: " & ExpectedValue & vbNewLine & "Provided: " & MyObject.toString
    End If
End Function

Function CheckPrimativeValue(MyTest, ExpectedValue)
    If MyTest <> ExpectedValue Then
        MsgBox "Expected: " & ExpectedValue & vbNewLine & "Provided: " & MyTest
    End If
End Function


