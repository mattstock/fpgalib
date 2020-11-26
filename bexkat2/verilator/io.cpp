#include "io.h"
#include <cstring>

IOModule::IOModule(const char n[]) {
  name = new char[strlen(n)];
  strcpy(name, n);
}

void IOModule::eval() {
}

void IOModule::reset() {
}

void IOModule::debug() {
}

void IOModule::dump() {
}

IOModule::~IOModule() {
  delete []name;
}
