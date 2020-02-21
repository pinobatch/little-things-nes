/*
2005-2012 Rich Felker

The following files are trivial, in my opinion not copyrightable in
the first place, and hereby explicitly released to the Public Domain:

All public headers within include/
*/
#ifndef MUSL_GETOPT_H
#define MUSL_GETOPT_H

#ifdef __cplusplus
extern "C" {
#endif

int musl_getopt(int, char * const [], const char *);
extern char *musl_optarg;
extern int musl_optind, musl_opterr, musl_optopt, musl_optreset;

struct musl_option
{
  const char *name;
  int has_arg;
  int *flag;
  int val;
};

int musl_getopt_long(int, char *const *, const char *, const struct musl_option *, int *);
int musl_getopt_long_only(int, char *const *, const char *, const struct musl_option *, int *);

#define musl_no_arg        0
#define musl_required_arg  1
#define musl_optional_arg  2

#ifdef __cplusplus
}
#endif

#endif
