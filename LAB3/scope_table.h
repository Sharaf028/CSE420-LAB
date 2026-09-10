#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
    unsigned long long hash = 0;

        for(char c : name)
        {
        hash = hash * 31 + c;
        }

    return hash % bucket_count;
    }

public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info* symbol);
    bool insert_in_scope(symbol_info* symbol);
    bool delete_from_scope(symbol_info* symbol);
    void print_scope_table(ofstream& outlog);
    ~scope_table();

    // you can add more methods if you need
};

// complete the methods of scope_table class
scope_table::scope_table()
{
    bucket_count = 0;
    unique_id = 0;
    parent_scope = NULL;
}

scope_table::scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
{
    this->bucket_count = bucket_count;
    this->unique_id = unique_id;
    this->parent_scope = parent_scope;

    table.resize(bucket_count);
}

scope_table* scope_table::get_parent_scope()
{
    return parent_scope;
}

int scope_table::get_unique_id()
{
    return unique_id;
}

symbol_info* scope_table::lookup_in_scope(symbol_info* symbol)
{
    int index = hash_function(symbol->get_name());

    for(symbol_info* temp : table[index])
    {
        if(temp->get_name() == symbol->get_name())
        {
            return temp;
        }
    }

    return NULL;
}

bool scope_table::insert_in_scope(symbol_info* symbol)
{
    // Check for duplicate symbol in current scope
    symbol_info* existing = lookup_in_scope(symbol);
    if(existing != NULL)
    {
        existing->set_type(symbol->get_type());
        existing->set_id_type(symbol->get_id_type());
        existing->set_symbol_type(symbol->get_symbol_type());
        existing->set_array_size(symbol->get_array_size());
        return false;
    }

    int index = hash_function(symbol->get_name());

    table[index].push_back(symbol);

    return true;
}

bool scope_table::delete_from_scope(symbol_info* symbol)
{
    int index = hash_function(symbol->get_name());

    for(auto it = table[index].begin(); it != table[index].end(); it++)
    {
        if((*it)->get_name() == symbol->get_name())
        {
            delete *it;              // Free the allocated memory
            table[index].erase(it);  // Remove from the list
            return true;
        }
    }

    return false;
}

void scope_table::print_scope_table(ofstream& outlog)
{
    outlog << "ScopeTable # " << unique_id << endl;

    for(int i = 0; i < bucket_count; i++)
    {
        if(table[i].empty()) continue;

        outlog << i << " --> " << endl;

        for(symbol_info* symbol : table[i])
        {
            outlog << "< " << symbol->get_name() << " : ID >" << endl;

            string kind = symbol->get_symbol_type();

            if(kind == "function")
            {
                outlog << "Function Definition" << endl;
                outlog << "Return Type: " << symbol->get_return_type() << endl;
                outlog << "Number of Parameters: " << symbol->get_parameter_count() << endl;
                outlog << "Parameter Details: ";

                vector<string> ptypes = symbol->get_parameter_types();
                vector<string> pnames = symbol->get_parameter_names();
                for(size_t j = 0; j < ptypes.size(); j++)
                {
                    if(j > 0) outlog << ", ";
                    outlog << ptypes[j] << " " << pnames[j];
                }
                outlog << endl;
            }
            else if(kind == "array")
            {
                outlog << "Array" << endl;
                outlog << "Type: " << symbol->get_id_type() << endl;
                outlog << "Size: " << symbol->get_array_size() << endl;
            }
            else
            {
                outlog << "Variable" << endl;
                outlog << "Type: " << symbol->get_id_type() << endl;
            }
        }

        outlog << endl;
    }
}

scope_table::~scope_table()
{
    for(int i = 0; i < bucket_count; i++)
    {
        for(symbol_info* symbol : table[i])
        {
            delete symbol;
        }
    }

    table.clear();
}