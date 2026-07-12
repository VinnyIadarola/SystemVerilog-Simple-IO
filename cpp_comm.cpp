#include <cstdio>
#include <map>
#include <string>
#include <fstream>

template<typename T = size_t>
class Cpp_Comm {
public:
    Cpp_Comm(
        std::string comm_dir,
        T start_cycle
    ) {
        comm_directory = comm_dir;
        curr_cycle = start_cycle;
    }

    Cpp_Comm() : Cpp_Comm(".", 0) {}

    int addInput(std::string signal_name, int &signal) {
        return addConnection(signal_name,  signal, inputs_to_DUT);
    }


    int addOutput(std::string signal_name, int &signal) {
        return addConnection(signal_name, signal, outputs_from_DUT);
    }

    int nextCycle(T cycle) {
        curr_cycle = cycle;
        return cycle;
    }

    int nextCycle() {
        return ++curr_cycle;
    }


    int grabCommVals() {
        std::ifstream file(format(comm_file_format, "SV", curr_cycle));
        if(!file.is_open()) return 1;
        
        for(std::string line; std::getline(file, line);) {
            size_t pos = line.find(":");
            if(pos == std::string::npos)
                continue;

            auto it = outputs_from_DUT.find(line.substr(0, pos));
            if(it == outputs_from_DUT.end())
                return 2;
            
            *(it->second) = stoi(line.substr(pos + 1, line.size()-1 - pos));
        }

        file.close();
        return 0;
    }


    int writeCommVals() {
        std::ofstream file(format(comm_file_format, "IO", curr_cycle));
        if(!file.is_open()) return 1;

         for(auto &[signal, value] : inputs_to_DUT) {
            file << signal << ":" << *value << std::endl; 
        }
      
        file.close();
        return 0;
    }



private:
    T curr_cycle;
    std::map<std::string, int*> inputs_to_DUT;
    std::map<std::string, int*> outputs_from_DUT;
    std::string comm_directory;
    constexpr static const char* comm_file_format = "{}_comm_cycle_{}.txt";

    int addConnection(std::string signal_name, int &signal, std::map<std::string, int*>& connection_map) {
        if (connection_map.find(signal_name) != connection_map.end())
            return 1;

        connection_map.emplace(std::move(signal_name), &signal);
        return 0;
    }


};




