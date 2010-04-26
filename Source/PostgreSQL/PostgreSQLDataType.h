//
//
//  This file is part of CocoaSQL
//
//  CocoaSQL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  CocoaSQL is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CocoaSQL.  If not, see <http://www.gnu.org/licenses/>.
//
//  PostgreSQLDataType.h by Igor Sutton on 4/26/10.
//

#ifndef __POSTGRESQL_DATA_TYPE__
#define __POSTGRESQL_DATA_TYPE__

//
// TODO: Find the proper way to wire PostgreSQL basic data types.
//
#define BYTEAOID   17
#define CHAROID    18
#define TEXTOID    25
#define INT8OID    20
#define INT2OID    21
#define INT4OID    23
#define NUMERICOID 1700
#define VARCHAROID 1043

#define FLOAT4OID 700
#define FLOAT8OID 701

#define DATEOID        1082
#define TIMEOID        1083
#define TIMESTAMPOID   1114
#define TIMESTAMPTZOID 1184

#endif