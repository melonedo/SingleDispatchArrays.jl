// https://discourse.julialang.org/t/union-splitting-vs-c/61772/20
// g++ -o lines -O3 -march=native -W -Wall  lines.cpp
#include <stdlib.h>
#include <sys/time.h>

#include <cstdio>
#include <vector>

struct LineAbstract {
  virtual double paint() = 0;
};

struct LineA : public LineAbstract {
  LineA(double l) { length = l; }
  virtual double paint() { return length; }
  double length;
};

struct LineB : public LineAbstract {
  LineB(double l) { length = l; }
  virtual double paint() { return length; }
  double length;
};

struct LineC : public LineAbstract {
  LineC(double l) { length = l; }
  virtual double paint() { return length; }
  double length;
};

struct LineD : public LineAbstract {
  LineD(double l) { length = l; }
  virtual double paint() { return length; }
  double length;
};

struct LineE : public LineAbstract {
  LineE(double l) { length = l; }
  virtual double paint() { return length; }
  double length;
};

struct Picture {
  Picture(std::vector<LineAbstract*> l) { lines = l; }
  std::vector<LineAbstract*> lines;
};

// Dynamic dispatch at runtime
double paint(Picture& p) {
  double s = 0.0;

  for (auto l : p.lines) s += l->paint();

  return s;
}

double tdiff(struct timeval t0, struct timeval t1) {
  return (t1.tv_sec - t0.tv_sec) + (t1.tv_usec - t0.tv_usec) / 1000000.0;
}

int main() {
  int n = 1000000;
  printf("n = %i \n", n);

  std::vector<LineAbstract*> lines;
  for (int i = 0; i < n; i++) {
    double r = ((double)rand() / (RAND_MAX));
    if (r <= 0.2)
      lines.push_back((LineAbstract*)new LineA(r));
    else if (r <= 0.4)
      lines.push_back((LineAbstract*)new LineB(r));
    else if (r <= 0.6)
      lines.push_back((LineAbstract*)new LineC(r));
    else if (r <= 0.8)
      lines.push_back((LineAbstract*)new LineD(r));
    else if (r <= 1.0)
      lines.push_back((LineAbstract*)new LineE(r));
  }

  Picture p(lines);

  struct timeval t0, t1;
  double t, res;

  // Store resulting sum, to make sure the calls aren't erased
  gettimeofday(&t0, NULL);
  res = paint(p);
  gettimeofday(&t1, NULL);
  t = tdiff(t0, t1);
  printf("dynamic dispatch : %.6f us per iteration (%.6f ms total) [%.6f]\n",
         t / n * 1000000, t * 1000, res);
}