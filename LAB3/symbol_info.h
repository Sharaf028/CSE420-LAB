#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;
    string id_type;
    string symbol_type;
    string return_type;
    int array_size = -1;
    bool is_void_function = false;
    vector<string> parameter_types;
    vector<string> parameter_names;

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;

        id_type = "";
        symbol_type = "";
        return_type = "";
    }
    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    string getname()
    {
    return get_name();
    }
    string get_symbol_type()
    {
        return symbol_type;
    }
    void set_symbol_type(string symbol_type)
    {
        this->symbol_type = symbol_type;
    }
    string get_id_type()
    {
        return id_type;
    }
    void set_id_type(string id_type)
    {
        this->id_type = id_type;
    }
    string get_return_type()
    {
    return return_type;
    }
    void set_return_type(string return_type)
    {
        this->return_type = return_type;
    }
    int get_array_size()
    {
    return array_size;
    }   
    void set_array_size(int size)
    {
    array_size = size;
    }
    void set_void_function(bool value)
    {
    is_void_function = value;
    }

    bool get_void_function()
    {
    return is_void_function;
    }
    vector<string> get_parameter_names()
    {
    return parameter_names;
    }

    vector<string> get_parameter_types()
    {
    return parameter_types;
    }

    int get_parameter_count()
    {
    return parameter_types.size();
    }
    void add_parameter(string name, string type)
    {
    parameter_names.push_back(name);
    parameter_types.push_back(type);
    }

    ~symbol_info()
    {
    parameter_names.clear();
    parameter_types.clear();
    }

};