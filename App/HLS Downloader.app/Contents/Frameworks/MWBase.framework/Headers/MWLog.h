//
//  MWLog.h
//  MWBase
//

#ifdef DEBUG
#define MWLog(format...)            MWDebug(__FILE__, __LINE__, format)
#else
#define MWLog(format...)            do {} while (0)
#endif

#define MWLogFullSel()              MWLog(@"%@", FULL_SEL_STR)

#define MWLogId(o)                  MWLog(@"%s = %@", # o, o)
#define MWLogInt(i)                 MWLog(@"%s = %d", # i, i)
#define MWLogUnsignedInt(u)         MWLog(@"%s = %u", # u, u)
#define MWLogBOOL(b)                MWLog(@"%s = %@", # b, b ? @"YES" : @"NO")
#define MWLogFloat(f)               MWLog(@"%s = %f", # f, f)
#define MWLogLongLong(l)            MWLog(@"%s = %lld", # l, l)
#define MWLogLongFloat(f)           MWLog(@"%s = %Lf", # f, f)
#define MWLogCGPoint(p)             MWLog(@"%s = %@", # p, NSStringFromCGPoint(p))
#define MWLogCGRect(r)              MWLog(@"%s = %@", # r, NSStringFromCGRect(r))
#define MWLogCGSize(s)              MWLog(@"%s = %@", # s, NSStringFromCGSize(s))
#define MWLogUIEdgeInsets(i)        MWLog(@"%s = %@", # i, NSStringFromUIEdgeInsets(i))
#define MWLogCGAffineTransform(a)   MWLog(@"%s = %@", # a, NSStringFromCGAffineTransform(a))
#define MWLogClass(o)               MWLog(@"%s = %@", # o, NSStringFromClass([o class]))
#define MWLogSelector(s)            MWLog(@"%s = %@", # s, NSStringFromSelector(s))
#define MWLogProtocol(p)            MWLog(@"%s = %@", # p, NSStringFromProtocol(p))
#define MWLogRange(r)               MWLog(@"%s = %@", # r, NSStringFromRange(r))

#define SEL_STR NSStringFromSelector(_cmd)
#define CLS_STR NSStringFromClass([self class])
#define FULL_SEL_STR [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]

extern void MWDebug(const char *fileName, int lineNumber, NSString *format, ...);