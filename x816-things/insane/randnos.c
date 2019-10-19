#include <stdio.h>
#include <stdlib.h>

int main(void)
{
  int i;
  FILE *fp;

  if((fp = fopen("randnos.bin", "wb")) == NULL)
  {
    perror("randnos.exe could not make randnos.bin\nbecause");
  };

  for(i = 0; i < 256; i++)
  {
    fputc(rand() % 5 + 2, fp);
  }
  fclose(fp);
  return 0;
}
