#pragma once

// ABOUT:
//  各種ダミー定義/実装、代替定義/実装 を用意したヘッダで、
//  コンパイラ機能で強制includeさせて使用することを想定している。
//  (元ソースになるべき書き足し、書き換えなく対応するため)

// ssize_t が無いので定義する
#if defined(_MSC_VER)
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;
#else
#ifndef SSIZE_MAX
// 参考: https://stackoverflow.com/questions/34580472/alternative-to-ssize-t-on-posix-unconformant-systems
#include <limits.h>
#include <stddef.h>
#include <inttypes.h>
#include <stdint.h>

#if SIZE_MAX == UINT_MAX
typedef int ssize_t;        /* common 32 bit case */
#define SSIZE_MIN  INT_MIN
#define SSIZE_MAX  INT_MAX
#elif SIZE_MAX == ULONG_MAX
typedef long ssize_t;       /* linux 64 bits */
#define SSIZE_MIN  LONG_MIN
#define SSIZE_MAX  LONG_MAX
#elif SIZE_MAX == ULLONG_MAX
typedef long long ssize_t;  /* windows 64 bits */
#define SSIZE_MIN  LLONG_MIN
#define SSIZE_MAX  LLONG_MAX
#elif SIZE_MAX == USHRT_MAX
typedef short ssize_t;      /* is this even possible? */
#define SSIZE_MIN  SHRT_MIN
#define SSIZE_MAX  SHRT_MAX
#elif SIZE_MAX == UINTMAX_MAX
typedef uintmax_t ssize_t;  /* last resort, chux suggestion */
#define SSIZE_MIN  INTMAX_MIN
#define SSIZE_MAX  INTMAX_MAX
#else
#error platform has exotic SIZE_MAX
#endif
#endif
#endif

// ダミーエラー関数
#include <stdint.h>
inline int android_errorWriteLog(int, const char*) { return 0; };
inline int android_errorWriteWithInfoLog(int tag, const char* subTag,
                                         int32_t uid, const char* data,
                                         uint32_t dataLen) {
  return 0;
};

// Layout.cpp が C++17 を要求するのだが、一方で libutils 由来の LruCache.h で 
// unary_function を使用していて、こちらは C++17 から廃止担ってるという問題がある。
// unary_function を定義そのまま用意して対応。
#if ((defined(_MSVC_LANG) && _MSVC_LANG >= 201703L) || __cplusplus >= 201703L)
namespace std {
  template<class ArgumentType, class ResultType>
  struct unary_function
  {
    typedef ArgumentType argument_type;
    typedef ResultType result_type;
  };
}
#endif

// gcc の ビルトインを再実装
// llvm-libc++/include/support/win32/support.h から拝借
#ifdef _MSC_VER
#include <intrin.h>

// Returns the number of leading 0-bits in x, starting at the most significant
// bit position. If x is 0, the result is undefined.
inline int __builtin_clzll(unsigned long long mask)
{
  unsigned long where;
// BitScanReverse scans from MSB to LSB for first set bit.
// Returns 0 if no set bit is found.
#if defined(_WIN64)
  if (_BitScanReverse64(&where, mask))
    return static_cast<int>(63 - where);
#elif defined(_WIN32)
  // Scan the high 32 bits.
  if (_BitScanReverse(&where, static_cast<unsigned long>(mask >> 32)))
    return static_cast<int>(63 -
                            (where + 32)); // Create a bit offset from the MSB.
  // Scan the low 32 bits.
  if (_BitScanReverse(&where, static_cast<unsigned long>(mask)))
    return static_cast<int>(63 - where);
#else
#error "Implementation of __builtin_clzll required"
#endif
  return 64; // Undefined Behavior.
}

inline int __builtin_clzl(unsigned long mask)
{
  unsigned long where;
  // Search from LSB to MSB for first set bit.
  // Returns zero if no set bit is found.
  if (_BitScanReverse(&where, mask))
    return static_cast<int>(31 - where);
  return 32; // Undefined Behavior.
}

inline int __builtin_clz(unsigned int x)
{
  return __builtin_clzl(x);
}

#endif