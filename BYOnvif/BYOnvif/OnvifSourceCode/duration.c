/*
	duration.c

	See duration.h for documentation.

	Compile this file and link it with your code.

gSOAP XML Web services tools
Copyright (C) 2000-2015, Robert van Engelen, Genivia Inc., All Rights Reserved.
This part of the software is released under ONE of the following licenses:
GPL or the gSOAP public license.
--------------------------------------------------------------------------------
gSOAP public license.

The contents of this file are subject to the gSOAP Public License Version 1.3
(the "License"); you may not use this file except in compliance with the
License. You may obtain a copy of the License at
http://www.cs.fsu.edu/~engelen/soaplicense.html
Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
for the specific language governing rights and limitations under the License.

The Initial Developer of the Original Code is Robert A. van Engelen.
Copyright (C) 2000-2015, Robert van Engelen, Genivia, Inc., All Rights Reserved.
--------------------------------------------------------------------------------
GPL license.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA 02111-1307 USA

Author contact information:
engelen@genivia.com / engelen@acm.org

This program is released under the GPL with the additional exemption that
compiling, linking, and/or using OpenSSL is allowed.
--------------------------------------------------------------------------------
A commercial use license is available from Genivia, Inc., contact@genivia.com
--------------------------------------------------------------------------------
*/

/* When using soapcpp2 option -q<name> or -p<name>, you need to change "soapH.h" below */

/* include soapH.h generated by soapcpp2 from .h file containing #import "duration.h" */
//#ifdef SOAP_H_FILE      /* if set, use the soapcpp2-generated fileH.h file as specified with: cc ... -DSOAP_H_FILE=fileH.h */
//# include "stdsoap2.h"
//# include SOAP_XSTRINGIFY(SOAP_H_FILE)
//#else
//# include "soapH.h"	/* or manually replace with soapcpp2-generated *H.h file */
//#endif

# include "stdsoap2.h"

#include "soapStub.h"

SOAP_FMAC3 void SOAP_FMAC4 soap_default_xsd__duration(struct soap *soap, LONG64 *a)
{
  (void)soap; /* appease -Wall -Werror */
  *a = 0;
}

SOAP_FMAC3 const char * SOAP_FMAC4 soap_xsd__duration2s(struct soap *soap, LONG64 a)
{
  LONG64 d;
  int k, h, m, s, f;
  if (a < 0)
  {
    soap_strcpy(soap->tmpbuf, sizeof(soap->tmpbuf), "-P");
    k = 2;
    a = -a;
  }
  else
  {
    soap_strcpy(soap->tmpbuf, sizeof(soap->tmpbuf), "P");
    k = 1;
  }
  f = a % 1000;
  a /= 1000;
  s = a % 60;
  a /= 60;
  m = a % 60;
  a /= 60;
  h = a % 24;
  d = a / 24;
  if (d)
    (SOAP_SNPRINTF(soap->tmpbuf + k, sizeof(soap->tmpbuf) - k, 21), SOAP_LONG_FORMAT "D", d);
  if (h || m || s || f)
  {
    if (d)
      k = strlen(soap->tmpbuf);
    if (f)
      (SOAP_SNPRINTF(soap->tmpbuf + k, sizeof(soap->tmpbuf) - k, 14), "T%02dH%02dM%02d.%03dS", h, m, s, f);
    else
      (SOAP_SNPRINTF(soap->tmpbuf + k, sizeof(soap->tmpbuf) - k, 10), "T%02dH%02dM%02dS", h, m, s);
  }
  else if (!d)
    soap_strcpy(soap->tmpbuf + k, sizeof(soap->tmpbuf) - k, "T0S");
  return soap->tmpbuf;
}

SOAP_FMAC3 int SOAP_FMAC4 by_soap_out_xsd__duration(struct soap *soap, const char *tag, int id, const LONG64 *a, const char *type)
{
  if (soap_element_begin_out(soap, tag, soap_embedded_id(soap, id, a, SOAP_TYPE_xsd__duration), type)
   || soap_string_out(soap, soap_xsd__duration2s(soap, *a), 0))
    return soap->error;
  return soap_element_end_out(soap, tag);
}

SOAP_FMAC3 int SOAP_FMAC4 soap_s2xsd__duration(struct soap *soap, const char *s, LONG64 *a)
{
  LONG64 sign = 1, Y = 0, M = 0, D = 0, H = 0, N = 0, S = 0;
  float f = 0.0;
  *a = 0;
  if (s)
  {
    if (*s == '-')
    {
      sign = -1;
      s++;
    }
    if (*s != 'P' && *s != 'p')
      return soap->error = SOAP_TYPE;
    s++;
    /* date part */
    while (s && *s)
    {
      char *r = NULL;
      LONG64 n;
      if (*s == 'T' || *s == 't')
      {
        s++;
	break;
      }
      n = soap_strtol(s, &r, 10);
      if (!r)
	return soap->error = SOAP_TYPE;
      s = r;
      switch (*s)
      {
        case 'Y':
        case 'y':
	  Y = n;
	  break;
	case 'M':
	case 'm':
	  M = n;
	  break;
	case 'D':
	case 'd':
	  D = n;
	  break;
	default:
	  return soap->error = SOAP_TYPE;
      }
      s++;
    }
    /* time part */
    while (s && *s)
    {
      char *r = NULL;
      LONG64 n;
      n = soap_strtol(s, &r, 10);
      if (!r)
	return soap->error = SOAP_TYPE;
      s = r;
      switch (*s)
      {
        case 'H':
        case 'h':
	  H = n;
	  break;
	case 'M':
	case 'm':
	  N = n;
	  break;
	case '.':
          {
            char tmp[32];
            int i;
            for (i = 0; i < 31; i++)
            {
              tmp[i] = *s++;
              if (*s < '0' || *s > '9')
                break;
            }
            tmp[i + 1] = '\0';
            if (soap_s2float(soap, tmp, &f))
              return soap->error;
            S = n;
            continue;
          }
	case 'S':
	case 's':
	  S = n;
	  break;
	default:
	  return soap->error = SOAP_TYPE;
      }
      s++;
    }
    /* convert Y-M-D H:N:S.f to signed long long int milliseconds */
    *a = sign * ((((((((((((Y * 12) + M) * 30) + D) * 24) + H) * 60) + N) * 60) + S) * 1000) + (LONG64)(1000.0 * f + 0.5));
  }
  return soap->error;
}

SOAP_FMAC3 LONG64 * SOAP_FMAC4 by_soap_in_xsd__duration(struct soap *soap, const char *tag, LONG64 *a, const char *type)
{
  if (soap_element_begin_in(soap, tag, 0, NULL))
    return NULL;
  if (*soap->type
   && soap_match_att(soap, soap->type, type)
   && soap_match_att(soap, soap->type, ":duration"))
  {
    soap->error = SOAP_TYPE;
    soap_revert(soap);
    return NULL;
  }
  a = (LONG64*)soap_id_enter(soap, soap->id, a, SOAP_TYPE_xsd__duration, sizeof(LONG64), NULL, NULL, NULL, NULL);
  if (*soap->href)
    a = (LONG64*)soap_id_forward(soap, soap->href, a, 0, SOAP_TYPE_xsd__duration, 0, sizeof(LONG64), 0, NULL, NULL);
  else if (a)
  {
    if (soap_s2xsd__duration(soap, soap_value(soap), a))
      return NULL;
  }
  if (soap->body && soap_element_end_in(soap, tag))
    return NULL;
  return a;
}
