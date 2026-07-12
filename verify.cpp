#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
using namespace std;

int width = 4;

int main () {
  string line;
  ifstream file("IO_comm_cyc_1.txt");
  if (!file.is_open()) {
    cerr << "Error opening file";
    return 1;
  }
  int sum = 0;
  while ( getline (file, line) ) {
    int pos = line.find(":");
    if (pos != string::npos) {
      sum += stoi(line.substr(pos + 1), nullptr, 16);
    }
  }
  file.close();
  int c = ((sum >> width) > 0) ? 1 : 0;
  int s = sum - (c << width); 
  stringstream stream;
  stream << hex << s;
  string hexsum = stream.str();
  stream.str("");
  stream.clear();

  ifstream fileout("sv_comm_cyc_1.txt");
  if (!fileout.is_open()) {
    cerr << "Error opening file";
    return 1;
  }
  string outc, outcexp;
  getline(fileout, outc);
  stream << "c:" << c;
  outcexp = stream.str();
  stream.str("");
  stream.clear();
  
  string outs, outsexp;
  getline(fileout, outs);
  stream << "s:" << hexsum;
  outsexp = stream.str();
  cout << outc << "\n";
  cout << outs << "\n";
  cout << outcexp << "\n";
  cout << outsexp << "\n";
  fileout.close();

  if (outs != outsexp || outc != outcexp) {
    cout << "Failed verification" << "\n";
    return 1;
  }

  return 0;
}
