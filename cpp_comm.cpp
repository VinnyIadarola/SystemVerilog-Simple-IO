#include <cstdio>
#include <unordered_map>
#include <string>
#include <fstream>
#include <thread>
#include <chrono>
#include <filesystem>

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


    int grabCommVals(bool deleteFile) {
        std::string input_file = format(COMM_FILE_FORMAT, "SV", curr_cycle);
        std::ifstream file(input_file);
        while(!file.is_open()) std::this_thread::sleep_for(std::chrono::milliseconds(500));
        

        for(std::string line; std::getline(file, line);) {
            size_t pos = line.find(":");
            if(pos == std::string::npos)
                continue;

            auto it = outputs_from_DUT.find(line.substr(0, pos));
            if(it == outputs_from_DUT.end())
                return 2;
            
            *(it->second) = std::stoi(line.substr(pos + 1), nullptr, 16);;
        }


        file.close();
        if (deleteFile && std::filesystem::remove(input_file)) 
            return 1;
        

        return 0;
    }


    int writeCommVals() {
        std::ofstream file(format(COMM_FILE_FORMAT, "IO", curr_cycle));
        if(!file.is_open()) return 1;

         for(auto &[signal, value] : inputs_to_DUT) {
            file << signal << ":" << std::hex << *value <<  std::dec << std::endl;
        }
      
        file.close();
        return 0;
    }

    int endCommunication() {
        std::ofstream file(format(COMM_FILE_FORMAT, "IO", curr_cycle));
        if(!file.is_open()) return 1;

        file << END_COMM_SIG << ":" << END_COMM_SIG << std::endl; 

        file.close();
        return 0;
    }



private:
    T curr_cycle;
    std::unordered_map<std::string, int*> inputs_to_DUT;
    std::unordered_map<std::string, int*> outputs_from_DUT;
    std::string comm_directory;
    constexpr static const char* COMM_FILE_FORMAT = "{}_comm_cycle_{}.txt";
    constexpr static const char* END_COMM_SIG = "END_OF_COMM";



    int addConnection(std::string signal_name, int &signal, std::unordered_map<std::string, int*>& connection_map) {
        if (connection_map.find(signal_name) != connection_map.end())
            return 1;

        connection_map.emplace(std::move(signal_name), &signal);
        return 0;
    }


};




