#pragma once

// Android の log 系マクロ等に対応するためのヘッダ
// log を Android 標準から変更
#ifndef ALOGE
#ifdef _DEBUG
#define ALOGE(...) (printf(__VA_ARGS__))
#else
#define ALOGE(...) ((void)0)
#endif
#ifndef LOGE
#define LOGE ALOGE
#endif
#ifndef ALOGW
#define ALOGW ALOGE
#endif
#ifndef ALOGD
#define ALOGD ALOGE
#endif
#endif

// TODO ひとまず握りつぶしておく系
#ifndef LOG_ALWAYS_FATAL_IF
// #define LOG_ALWAYS_FATAL_IF(...) ((void)0)
#define LOG_ALWAYS_FATAL_IF(cond,...) if (cond){abort();}
#endif

