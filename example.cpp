#include <iostream>
#include "cpp_comm.cpp"

const int W = 4;
const bool delete_read_file = false;
const int LARGE_CYCLE = 100;
const int END_CYCLE = 3;

int add(int a, int b) {
  return a + b;
}

int calculate_c(int a, int b) {
  return add(a, b) >> W;
}

int calculate_s(int a, int b) {
  return add(a, b) - (calculate_c(a, b) << W);
}

int main() {
  Cpp_Comm  comm;
  size_t cycle = comm.nextCycle(); // skipping past cycle 0 to read inputs

  // 7 and 4 are magic numbers, example values for addition
  int a = 7;
  int b = 4;
  int c;
  int s;

  int expected_c = calculate_c(a, b);
  int expected_s = calculate_s(a, b);

  comm.addInput("a", a);
  comm.addInput("b", b);
  comm.addOutput("c", c);
  comm.addOutput("s", s);

  if (comm.writeCommVals() == 1) {
    std::cout << "Could not open IO file in cycle " << cycle << std::endl;
    return 1;
  }

  if (comm.grabCommVals(delete_read_file) == 2) {
    std::cout << "Output key not found in cycle " << cycle << std::endl;
    return 1;
  }

  if (c != expected_c || s != expected_s) {
    if (c != expected_c)
      std::cout << "Mismatched c value " << std::hex << c << " differs from expected " << expected_c << std::endl; 
    if (s != expected_s)
      std::cout << "Mismatched s value " << std::hex << s << " differs from expected " << expected_s << std::endl; 
    return 1;
  }

  // Testing logic for a subsequent cycle
  cycle = comm.nextCycle();
  a = 8;
  b = 13;

  expected_c = calculate_c(a, b);
  expected_s = calculate_s(a, b);

  if (comm.writeCommVals() == 1) {
    std::cout << "Could not open IO file in cycle " << cycle << std::endl;
    return 1;
  }

  if (comm.grabCommVals(delete_read_file) == 2) {
    std::cout << "Output key not found in cycle " << cycle << std::endl;
    return 1;
  }

  if (c != expected_c || s != expected_s) {
    if (c != expected_c)
      std::cout << "Mismatched c value " << std::hex << c << " differs from expected " << expected_c << std::endl; 
    if (s != expected_s)
      std::cout << "Mismatched s value " << std::hex << s << " differs from expected " << expected_s << std::endl; 
    return 1;
  } 
 
  // Setting cycle number to a number that won't be used otherwise, to ensure no file is present
  cycle = comm.nextCycle(LARGE_CYCLE);

  // Atomic variable to check if thread completed grabCommVals, captured by reference
  std::atomic<bool> received(false);

  std::thread poll_thread([&comm, &received](){
      comm.grabCommVals(delete_read_file);
      received = true;
    });

  if (poll_thread.joinable()) {
    poll_thread.detach();
  }

  std::this_thread::sleep_for(std::chrono::milliseconds(2000));

  if (received) { 
    std::cout << "Received unintended SV comm in cycle " << LARGE_CYCLE << std::endl;
    return 1;
  }

  cycle = comm.nextCycle(END_CYCLE);
  if (comm.endCommunication() == 1) {
    std::cout << "Could not end communication in cycle " << cycle << std::endl;
    return 1;
  }

  return 0; 
}
