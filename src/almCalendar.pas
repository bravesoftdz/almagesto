{
    almCalendar is part of Almagesto, a Free Pascal astronomical library.

    Copyright (C) 2011,2016 João Marcelo S. Vaz

    Almagesto is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Almagesto is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
}

//  This unit has calendar manipulation routines.
unit almCalendar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TFixedDate = Extended;

// Fixed Date Calendar (Julian Date, Rata Die and TDateTime) functions
function FixedDateToJulianDate(FixedDate: TFixedDate): TFixedDate;
function JulianDateToFixedDate(JulianDate: TFixedDate): TFixedDate;
function FixedDateToRataDie(FixedDate: TFixedDate): TFixedDate;
function RataDieToFixedDate(RataDie: TFixedDate): TFixedDate;
function FixedDateToDateTime(FixedDate: TFixedDate): TFixedDate;
function DateTimeToFixedDate(DateTime: TFixedDate): TFixedDate;

// Julian Calendar functions
procedure FixedDateToJulianCalendar(FixedDate: TFixedDate; out Year,Month,Day: Integer); overload;
function JulianCalendarToFixedDate(Year, Month, Day: Integer): TFixedDate; overload;
function JulianLeapYear(Year: Integer): Boolean;

// Gregorian Calendar functions
procedure FixedDateToGregorianCalendar(FixedDate: TFixedDate; out Year,Month,Day: Integer);
function GregorianCalendarToFixedDate(Year, Month, Day: Integer): TFixedDate;
function GregorianLeapYear(Year: Integer): Boolean;

// Mayan Calendar functions
type
  TMayanCorrelation = (mcGoodmanMartinezThompson,mcSpinden);
function MayanLongCountToFixedDate(Baktun, Katun, Tun, Uinal, Kin: Integer; MayanCorrelation: TMayanCorrelation = mcGoodmanMartinezThompson): TFixedDate;
procedure FixedDateToMayanLongCount(FixedDate: TFixedDate; out Baktun, Katun, Tun, Uinal, Kin: Integer; MayanCorrelation: TMayanCorrelation = mcGoodmanMartinezThompson);
procedure FixedDateToMayanHaab(FixedDate: TFixedDate; out Day, Month: Integer; MayanCorrelation: TMayanCorrelation = mcGoodmanMartinezThompson);
procedure FixedDateToMayanTzolkin(FixedDate: TFixedDate; out Number, Name: Integer; MayanCorrelation: TMayanCorrelation = mcGoodmanMartinezThompson);


type
  TFixedDateEpochType = (fdeJulianDate, fdeRataDie, fdeDateTime);

function FixedDateEpoch(FixedDateEpochType: TFixedDateEpochType): TFixedDate;
function JulianDateEpoch: TFixedDate;
function RataDieEpoch: TFixedDate;
function DateTimeEpoch: TFixedDate;
function JulianCalendarEpoch: TFixedDate;
function GregorianCalendarEpoch: TFixedDate;
function MayanEpoch(MayanCorrelation: TMayanCorrelation = mcGoodmanMartinezThompson): TFixedDate;

var
  FixedDateEpochType: TFixedDateEpochType = fdeJulianDate;

implementation

uses Math;

(******************************************************************************)
(*                             helper routines                                *)
(*                                                                            *)

function CalMod(x, y: Extended): Extended; overload;
begin
  Result:= x - y*Floor(x/y);
end;

function CalMod(x, y: Integer): Integer; overload;
begin
  Result:= x - y*Floor(x/y);
end;

function CalAMod(x, y: Extended): Extended; overload;
begin
  Result:= y + CalMod(x, -y);
end;

function CalAMod(x, y: Integer): Integer; overload;
begin
  Result:= y + CalMod(x, -y);
end;
(******************************************************************************)

(******************************************************************************)
(*                         Calendar Epoch routines                            *)
(*                                                                            *)

const
{ Julian Date Epoch is:
  JulianDate: 0
  RataDie: -1721424.5
  Julian Calendar: Noon, January 1, 4713 BCE (-4712)
  Gregorian Calendar: Noon, November 24, -4713
}
  JulianDateEpochInRataDie = -1721424.5;

{ Rata Die Epoch is:
  RataDie: 0
  JulianDate: 1721424.5
  Julian Calendar:
  Gregorian Calendar: Midnight, December 31, 0
}
  RataDieEpochInRataDie = 0;

  // DateTime Epoch is Midnight, December 30, 1899 (Gregorian)
  DateTimeEpochInRataDie = 693594.5;

{ Julian Calendar Epoch is:
  RataDie: -1
  Julian Calendar: Midnight, January 1, 1 CE
  Gregorian Calendar: Midnight, December 30, 0
}
  JulianCalendarEpochInRataDie = -1;

{ Gregorian Calendar Epoch is:
  RataDie: 1
  Julian Calendar: Midnight, January 3, 1 CE
  Gregorian Calendar: Midnight, January 1, 1 CE
}
  GregorianCalendarEpochInRataDie = 1;

{ Mayan Long Count Calendar Epoch depends on the precise correlation between the
  Western calendars and the Long Count calendar. The generally accepted
  correlation constant is the Modified Thompson 2, "Goodman–Martinez–Thompson",
  or GMT correlation of JD 584282.5.
}
  Mayan_GoodmanMartinezThompsonInRataDie = -1137142;    //   06/sep/3114 BCE (Julian calendar)
  Mayan_SpindenInJulianDate              = 489383.5;    //   11/nov/3374 BCE (Julian calendar)


function FixedDateEpoch(FixedDateEpochType: TFixedDateEpochType): TFixedDate;
begin
  case FixedDateEpochType of
    fdeJulianDate: Result:= JulianDateEpochInRataDie;
    fdeRataDie: Result:= RataDieEpochInRataDie;
    fdeDateTime: Result:= DateTimeEpochInRataDie;
  end;
end;

function JulianDateEpoch: TFixedDate;
begin
  Result:= JulianDateEpochInRataDie - FixedDateEpoch(FixedDateEpochType);
end;

function RataDieEpoch: TFixedDate;
begin
  Result:= RataDieEpochInRataDie - FixedDateEpoch(FixedDateEpochType);
end;

function DateTimeEpoch: TFixedDate;
begin
  Result:= DateTimeEpochInRataDie - FixedDateEpoch(FixedDateEpochType);
end;

function JulianCalendarEpoch: TFixedDate;
begin
  Result:= JulianCalendarEpochInRataDie - FixedDateEpoch(FixedDateEpochType);
end;

function GregorianCalendarEpoch: TFixedDate;
begin
  Result:= GregorianCalendarEpochInRataDie - FixedDateEpoch(FixedDateEpochType);
end;

function MayanEpoch(MayanCorrelation: TMayanCorrelation): TFixedDate;
begin
  case MayanCorrelation of
    mcGoodmanMartinezThompson:
      Result:= Mayan_GoodmanMartinezThompsonInRataDie  - FixedDateEpoch(FixedDateEpochType);
    mcSpinden:
      Result:= JulianDateToFixedDate(Mayan_SpindenInJulianDate);
  end;
end;

(******************************************************************************)



(******************************************************************************)
(*                          Fixed Date functions                              *)
(*                   Julian Date, Rata Die and TDateTime                      *)

function FixedDateToJulianDate(FixedDate: TFixedDate): TFixedDate;
begin
  Result:= FixedDate - JulianDateEpoch;
end;

function JulianDateToFixedDate(JulianDate: TFixedDate): TFixedDate;
begin
  Result:= JulianDate + JulianDateEpoch;
end;

function FixedDateToRataDie(FixedDate: TFixedDate): TFixedDate;
begin
  Result:= FixedDate - RataDieEpoch;
end;

function RataDieToFixedDate(RataDie: TFixedDate): TFixedDate;
begin
  Result:= RataDie + RataDieEpoch;
end;

function FixedDateToDateTime(FixedDate: TFixedDate): TFixedDate;
begin
  Result:= FixedDate - DateTimeEpoch;
end;

function DateTimeToFixedDate(DateTime: TFixedDate): TFixedDate;
begin
  Result:= DateTime + DateTimeEpoch;
end;
(******************************************************************************)




(******************************************************************************)
(*                       Julian Calendar functions                            *)
(*                                                                            *)

{Fixed Date of Julian Calendar starting epoch (at preceding midnight)
  Julian: 01/jan/01 CE - Gregorian: 30/dec/01 BCE
}
function JulianCalendarToFixedDate(Year, Month, Day: Integer): TFixedDate; overload;
var
  c: Integer;
begin
  c:= 0;
  if Month > 2 then
    if JulianLeapYear(Year) then
      c:= -1
    else
      c:= -2;
  Result:= 365*(Year - 1) + Floor((Year - 1)/4) + Floor((367*Month - 362)/12) + Day + c - 1;
  Result:= Result + JulianCalendarEpoch;
end;

procedure FixedDateToJulianCalendar(FixedDate: TFixedDate; out Year, Month,
  Day: Integer);
var
  c: Integer;
begin
  Year:= Floor((4*Floor(FixedDate - JulianCalendarEpoch) + 1464)/1461);
  c:= 0;
  if (FixedDate - JulianCalendarToFixedDate(Year,3,1)) >= 0 then
    if JulianLeapYear(Year) then
      c:= 1
    else
      c:= 2;
  Month:= Floor((12*(Floor(FixedDate - JulianCalendarToFixedDate(Year,1,1)) + c) + 373)/367);
  Day:=  Floor(FixedDate - JulianCalendarToFixedDate(Year,Month,1)) + 1;
end;

function JulianLeapYear(Year: Integer): Boolean;
// verify if the Julian Year is Leap year
// this function doesn't use de BCE notation, i.e,
//     years are  ...  -2,    -1,     0,     1,    2,    3  ...
//     that means ... 3 BCE, 2 BCE, 1 BCE, 1 CE, 2 CE, 3 CE ...
// and doesn't use the historical leap year before 9 CE
// tha would be 45, 42, 39, 36, 33, 30, 27, 24, 21, 18, 15, 12, 9
begin
  Result:= (CalMod(Year,4) = 0);
end;
(******************************************************************************)

(******************************************************************************)
(*                    Gregorian Calendar functions                            *)
(*                                                                            *)

{Fixed of Gregorian Calendar starting epoch (at preceding midnight)
  Gregorian: 01/jan/01 CE - Julian: 03/jan/01 CE
}
function GregorianCalendarToFixedDate(Year, Month, Day: Integer): TFixedDate;
var
  c: Integer;
begin
  c:= 0;
  if Month > 2 then
    if GregorianLeapYear(Year) then
      c:= -1
    else
      c:= -2;
  Result:= 365*(Year - 1) + Floor((Year - 1)/4) - Floor((Year - 1)/100) +
           Floor((Year - 1)/400) + Floor((367*Month - 362)/12) + Day + c - 1;
  Result:= Result + GregorianCalendarEpoch;
end;

function FixedDateToGregorianYear(FixedDate: TFixedDate): Integer;
var
  d0, n400, d1, n100, d2, n4, d3, n1: Integer;
begin
  d0:= Floor(FixedDate - GregorianCalendarEpoch);
  n400:= Floor(d0/146097);
  d1:= CalMod(d0,146097);
  n100:= Floor(d1/36524);
  d2:= CalMod(d1,36524);
  n4:= Floor(d2/1461);
  d3:= CalMod(d2,1461);
  n1:= Floor(d3/365);
  Result:= 400*n400 + 100*n100 + 4*n4 + n1;
  if (n100 <> 4) and (n1 <> 4) then
    Inc(Result);
end;

procedure FixedDateToGregorianCalendar(FixedDate: TFixedDate; out Year, Month,
  Day: Integer);
var
  c: Integer;
begin
  Year:= FixedDateToGregorianYear(FixedDate);
  c:= 0;
  if (FixedDate - GregorianCalendarToFixedDate(Year,3,1)) >= 0 then
    if GregorianLeapYear(Year) then
      c:= 1
    else
      c:= 2;
  Month:= Floor((12*(Floor(FixedDate - GregorianCalendarToFixedDate(Year,1,1)) + c) + 373)/367);
  Day:= Floor(FixedDate - GregorianCalendarToFixedDate(Year,Month,1)) + 1;
end;

function GregorianLeapYear(Year: Integer): Boolean;
begin
  Result:= ( (CalMod(Year,4) = 0) and ( (CalMod(Year,100) <> 0) or (CalMod(Year,400) = 0) ) )
end;



(******************************************************************************)
(*                        Mayan Calendar functions                            *)
(*                                                                            *)

function MayanLongCountToFixedDate(Baktun, Katun, Tun, Uinal, Kin: Integer;
  MayanCorrelation: TMayanCorrelation): TFixedDate;
begin
  Result:= (((Baktun*20 + Katun)*20 + Tun)*18 + Uinal)*20 + Kin;
  Result:= Result + MayanEpoch(MayanCorrelation);
end;

procedure FixedDateToMayanLongCount(FixedDate: TFixedDate; out Baktun, Katun,
  Tun, Uinal, Kin: Integer; MayanCorrelation: TMayanCorrelation);
var
  Days: Integer;
begin
  Days:= Floor(FixedDate - MayanEpoch(MayanCorrelation));
  Baktun:= Floor(Days/144000);
  Days:= CalMod(Days,144000);
  Katun:= Floor(Days/7200);
  Days:= CalMod(Days,7200);
  Tun:= Floor(Days/360);
  Days:= CalMod(Days,360);
  Uinal:= Floor(Days/20);
  Kin:= CalMod(Days,20);
end;

procedure FixedDateToMayanHaab(FixedDate: TFixedDate; out Day, Month: Integer;
  MayanCorrelation: TMayanCorrelation);
var
  Days: Integer;
begin
  Days:= Floor(FixedDate - MayanEpoch(MayanCorrelation));
  // on starting epoch of Mayan Long Count it was '8 Cumku' (8-18)
  Days:= Days + 348; // there are 348 days to '8 Cumku'
  Days:= CalMod(Days,365);
  Month:= 1 + Floor(Days/20);
  Day:= CalMod(Days,20);
end;

procedure FixedDateToMayanTzolkin(FixedDate: TFixedDate; out Number,
  Name: Integer; MayanCorrelation: TMayanCorrelation);
var
  Days: Integer;
begin
  Days:= Floor(FixedDate - MayanEpoch(MayanCorrelation));
  // on starting epoch of Mayan Long Count it was '4 Ahau' (4-20)
  Days:= Days + 160; // there are 160 days to '4 Ahau'
  Name:= CalAMod(Days,20);
  Number:= CalAMod(Days,13);
end;

(******************************************************************************)

end.

