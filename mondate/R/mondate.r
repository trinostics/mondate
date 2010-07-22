### mondate.r
### S4 class to store and calculate dates in terms of months, 
###     and fractional parts thereof.

### - Dan Murphy, June 1, 2010

##    Copyright (C) <2010>  <Daniel Murphy>

##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


##  SCALARS

.mondate.tolerance <- .Machine$double.eps^0.5
.motbl<-c(31,28,31,30,31,30,31,31,30,31,30,31)

.mondate.origin <- "1999-12-31"
    .mondate.year.zero <- 2000
    .ISO.origin <- "1899-12-31"
    .ISO.year.zero <- 1900
    .origin.diff.years <- .mondate.year.zero-.ISO.year.zero
    .mondate.days.zero <- as.numeric(as.Date(.mondate.origin))
    .as.Date.origin <- "1970-1-1"

.displayFormat <- c(US="%m/%d/%Y", # US format
                   USb="%m-%d-%Y", 
                   EU="%Y-%m-%d", # EU format
                   EUb="%Y/%m/%d")
.default.displayFormat <- ifelse (
    length(grep("United States",Sys.getlocale("LC_TIME")))!=1L,
        .displayFormat[3L], .displayFormat[1L]
    )
.default.timeunits <- "months"

.date.classes <- c("Date","POSIXt","POSIXct","POSIXlt")

##  USEFUL INTERNAL FUNCTIONS

.is.leapyear<-function(yr) yr%%400==0 | (yr%%4==0 & yr%%100!=0)
.daysinmonth<-function(yr,mo){
    if (length(yr)>length(mo)) mo<-rep(mo,length(yr)/length(mo)+1)[1:length(yr)]
    else
    if (length(yr)<length(mo)) yr<-rep(yr,length(mo)/length(yr)+1)[1:length(mo)]
    days<-.motbl[mo]
    days[.is.leapyear(yr)&mo==2]<-29
    days
    }

##  THE CLASS

setClassUnion("numarray",c("numeric","array"))
setClass("mondate",
    representation(
        displayFormat="character",
        timeunits="character"),
    contains="numarray",
    prototype=prototype(
        numeric(0),
        displayFormat=.default.displayFormat,
        timeunits=.default.timeunits),
    S3methods=TRUE
    )

## S4 METHODS

## SLOT ACCESS
setGeneric("mondateDisplayFormat", function(x) standardGeneric("mondateDisplayFormat"))
setMethod("mondateDisplayFormat","mondate", function(x) x@displayFormat)
setMethod("mondateDisplayFormat","ANY", function(x) NULL)
setGeneric("mondateDisplayFormat<-",function(x,value) standardGeneric("mondateDisplayFormat<-"))
setReplaceMethod("mondateDisplayFormat", "mondate", function(x, value) { 
    x@displayFormat <- value
    x 
    })

setGeneric("mondateTimeunits", function(x) standardGeneric("mondateTimeunits"))
setMethod("mondateTimeunits","mondate", function(x) x@timeunits)
setMethod("mondateTimeunits","ANY", function(x) NULL)
setGeneric("mondateTimeunits<-",function(x,value) standardGeneric("mondateTimeunits<-"))
setReplaceMethod("mondateTimeunits", "mondate", function(x, value) { 
    x@timeunits <- value
    x 
    })

# CONVERSION TO MONDATE

setGeneric("mondate", function(x, displayFormat=.default.displayFormat, 
                               timeunits=.default.timeunits, ...) 
                      standardGeneric("mondate"))
setMethod("mondate", "mondate", function(x, displayFormat, timeunits, ...) {
    new("mondate", x, displayFormat=displayFormat, timeunits=timeunits, ...)
    })
setMethod("mondate", "numeric", function(x, 
            displayFormat, timeunits=c("months","years","days"), ...) {
    timeunits<-match.arg(timeunits)
    if (timeunits=="months") new("mondate", x, 
                                 displayFormat=displayFormat, 
                                 timeunits=timeunits, ...)
    else
    if (timeunits=="years")  new("mondate", 12*x, 
                                 displayFormat=displayFormat, 
                                 timeunits=timeunits, ...) 
    else {
        # x represents the number of days since beginning of 01/01/2000
        x<-as.POSIXlt(as.Date(x, origin=.mondate.origin))
        new("mondate", (x$year-.origin.diff.years)*12+x$mon+x$mday /
                       .daysinmonth(x$year+.ISO.year.zero,x$mon+1), 
            displayFormat=displayFormat, timeunits=timeunits, ...)
        }
    })
.date.to.mondate <- function(x, displayFormat, timeunits, ...) {
    x <- as.POSIXlt(x, ...)
    # Note that per ISO standard, x is time since 1900; i.e., 
    #   close of business 12/31/1899.
    new("mondate", (x$year-.origin.diff.years)*12+x$mon+x$mday /
                   .daysinmonth(x$year+.ISO.year.zero,x$mon+1), 
        displayFormat=displayFormat, timeunits=timeunits, ...)
    }
setMethod("mondate", "Date",   .date.to.mondate)
setMethod("mondate", "POSIXt", .date.to.mondate)

setMethod("mondate", "character", function(x, displayFormat, timeunits, ...) {
    if (missing(displayFormat)) {
        displayFormat <- .default.displayFormat
        m <- match(TRUE,!is.na(x))
        d <- as.Date(x[m], format=displayFormat)
        if (!is.na(d)) return(mondate(as.Date(x, format=displayFormat, ...),
                                      displayFormat=displayFormat, 
                                      timeunits=timeunits, ...))
        for (i in 1:4) {
            d<-as.Date(x[m],format=.displayFormat[i], ...)
            if (!is.na(d)) break
            }
        if (is.na(d)) {
            warning("mondate character", 
                    "first non-NA element '", x[m],
                    "' not a date. Converting to numeric")
            mondate(as.numeric(x), 
                    displayFormat=displayFormat, timeunits=timeunits, ...)
            }
        else {
            x<-as.Date(x,format=.displayFormat[i], ...)
            .date.to.mondate(x, displayFormat=.displayFormat[i], 
                             timeunits=timeunits, ...)
            }
        }
    else .date.to.mondate(as.Date(x, format=displayFormat, ...), 
                          displayFormat=displayFormat, 
                          timeunits=timeunits, ...)
    })
setMethod("mondate", "array", function(x, displayFormat, timeunits, ...) {
    dims <- dim(x)
    dimnams <- dimnames(x)
    dim(x) <- NULL
    y<-callNextMethod()
    dim(y) <- dims
    dimnames(y) <- dimnams
    y
    })
setMethod("mondate", "ANY", function(x, displayFormat, timeunits, ...) { 
    y <- tryCatch(as.Date(x, ...), 
        error = function(e) tryCatch(as.numeric(x),
            error=function(e) stop("Cannot convert class '", 
                                   class(x),
                                   "' to class 'mondate'"),
            finally = warning("Converting class '", 
                class(x), 
                "' to class 'mondate' via 'as.numeric'. Check results!",
                call.=FALSE)
            )
        )
    mondate(y, displayFormat=displayFormat, timeunits=timeunits)
    })

# Finally, if users have an S3 class for which a coerce-to-mondate
#   method has been written (e.g., as.mondate.foo) this will enable it.
#as.mondate <- function(x,...) UseMethod("as.mondate")

# CONVERSION FROM MONDATE

setGeneric("as.Date")
setMethod("as.Date","mondate", function(x, ...) {
    x<-unclass(x)
    ym<-floor(x)
    y<-ym%/%12L+.mondate.year.zero
    m <- ym%%12 + 1
    d<-ceiling(round((x-ym)*.daysinmonth(y,m),7))
    nna<-!is.na(x)
    i<-(abs(x-round(x)) < .mondate.tolerance)
    d[i&nna]<-1
    z<-as.Date(rep(NA,length(x)))
    z[nna]<-as.Date(paste(y[nna],m[nna],d[nna],sep="-"), format="%Y-%m-%d")
    z[i&nna]<-z[i&nna]-1
    z
    })
setGeneric("as.POSIXlt")
setMethod("as.POSIXlt","mondate", function(x, tz="", ...) 
    as.POSIXlt(as.Date(x), ...))
setGeneric("as.POSIXct")
setMethod("as.POSIXct","mondate", function(x,  tz="", ...) 
    as.POSIXct(as.POSIXlt(as.Date(x), ...)))

setMethod("as.numeric", "mondate", function(x, 
               convert=FALSE, timeunits=c("months","years","days"), ...) {
    if (missing(timeunits)) timeunits <- slot(x,"timeunits")
    if (!convert) y <- getDataPart(x) 
    else {
        if (timeunits=="months") y<-c(getDataPart(x))
        else
        if (timeunits=="years") y<-c(getDataPart(x)/12)
        else y<-c(as.numeric(as.Date(x)))-.mondate.days.zero
        attr(y,"timeunits") <- timeunits
        }
    y
    })

setMethod("as.character","mondate", function(x, displayFormat, ...) {
    if (missing(displayFormat)) displayFormat <- slot(x,"displayFormat")
    dims <- dim(x)
    dimnms <- dimnames(x)
    nams <- names(x)
    i<-is.infinite(x)
    x<-format(as.Date(x), format=displayFormat, ...)
    x[i]<-"Inf"
    dim(x) <- dims
    if (is.null(dims)) names(x) <- nams
    else dimnames(x) <- dimnms
    x
    })

## DATE ARITHMETIC

setMethod("Compare", "mondate", function(e1,e2) 
    callGeneric(getDataPart(e1),getDataPart(e2))
    )

setMethod("Arith",c("mondate","mondate"),function(e1,e2) {
    if (missing(e2)) 
        x<-mondate(callGeneric(as.numeric(e1, convert=TRUE)), 
                timeunits=e1@timeunits, displayFormat=e1@displayFormat)
    else {
        timeunits <- e1@timeunits
        if (timeunits!=e2@timeunits) 
            warning("Unequal timeunits, using first mondate's= ", timeunits)
        if (timeunits=="months") 
            x<-callGeneric(unclass(e1),unclass(e2))
        else
        if (timeunits=="years") x<-callGeneric(unclass(e1),unclass(e2))/12
        else x<-callGeneric(as.Date(e1),as.Date(e2))
        attributes(x)<-NULL
        attr(x,"timeunits") <- timeunits
        }
    x
    })
setMethod("Arith",c("numeric","mondate"),function(e1,e2)
    mondate(callGeneric(e1, as.numeric(e2,convert=TRUE)), 
            timeunits=e2@timeunits, displayFormat=e2@displayFormat)
    )
setMethod("Arith",c("mondate","numeric"),function(e1,e2)
    mondate(callGeneric(as.numeric(e1,convert=TRUE),e2), 
            timeunits=e1@timeunits, displayFormat=e1@displayFormat)
    )

setMethod("Summary","mondate", function(x, ..., na.rm = FALSE) 
    mondate(callGeneric(x@.Data, ..., na.rm=na.rm), 
            timeunits=x@timeunits, displayFormat=x@displayFormat)
    )

# OTHER ARITHMETIC FUNCTIONS

setGeneric("mean")
setMethod("mean", signature="mondate", function(x, ...) {
    L <- list(...)
    if (length(L)>0L) x <- c(x,L)
    new("mondate", callNextMethod(getDataPart(x)), 
                   displayFormat=x@displayFormat, 
                   timeunits=x@timeunits)
    })

setGeneric("unique")
setMethod("unique","mondate", function(x, incomparables=F, ...) 
    mondate(callNextMethod(x=getDataPart(x), incomparables=incomparables, ...), 
            displayFormat=x@displayFormat, timeunits=x@timeunits) 
    )

## COMBINING, EXTRACTING, SHAPING, ETC.
setMethod("c", "mondate", function(x, ..., recursive=FALSE) {
    L<-list(...)
    if (length(L)>0L) 
        new("mondate", sapply(unlist(list(x, L)),getDataPart), 
                       displayFormat=x@displayFormat, 
                       timeunits=x@timeunits)
    else
        new("mondate", c(getDataPart(x)), 
                       displayFormat=x@displayFormat, 
                       timeunits=x@timeunits)

    })

setMethod("[", "mondate", function(x, i, j, ..., drop) 
    new("mondate", callNextMethod(), 
                   displayFormat=x@displayFormat, timeunits=x@timeunits)
    )

setMethod("rep", "mondate", function(x, ...)
    mondate(callNextMethod(x@.Data, ...), 
            displayFormat=x@displayFormat, timeunits=x@timeunits)
    )

setGeneric("array")
setMethod("array","mondate", 
          function(data = NA, dim = length(data), dimnames = NULL) {
    dim(data)<-dim
    dimnames(data)<-dimnames
    data
    })

setGeneric("matrix")
setMethod("matrix","mondate",
          function(data, nrow, ncol=1, byrow=FALSE, dimnames=NULL) {
    if(!byrow & (nrow*ncol==length(data))) {
        dim(data)<-c(nrow,ncol)
        dimnames(data)<-dimnames
        return(data)
        }
    if (!missing(nrow) && !missing(ncol))
        mondate(callNextMethod(as.numeric(data, convert=TRUE), nrow=nrow,
                                                  ncol=ncol,
                                                  byrow=byrow,
                                                  dimnames=dimnames),
                timeunits=data@timeunits, displayFormat=data@displayFormat)
    else
    if (missing(nrow))
        mondate(callNextMethod(as.numeric(data, convert=TRUE), ncol=ncol,
                                                  byrow=byrow,
                                                  dimnames=dimnames),
                timeunits=data@timeunits, displayFormat=data@displayFormat)
    else
        mondate(callNextMethod(as.numeric(data, convert=TRUE), nrow=nrow,
                                                  byrow=byrow,
                                                  dimnames=dimnames),
                timeunits=data@timeunits, displayFormat=data@displayFormat)
    })

# C/RBIND subsection

setClassUnion("mondAtomic",
	      members = c("logical", "integer", "numeric", "character"))
setClassUnion("mondArray_or_Atomic",
	      members = c("array", "matrix", "mondAtomic"))
setClassUnion("mondate_possible",
	      members = c("mondArray_or_Atomic", "mondate"))

setClassUnion("mondAtomic_w_date",
	      members = c("mondAtomic", .date.classes))
setClassUnion("mondArray_or_Atomic_w_date",
	      members = c("array", "matrix", "mondAtomic_w_date"))
setClassUnion("mondate_possible_w_date",
	      members = c("mondArray_or_Atomic_w_date", "mondate"))

.crbindnames <- function(L, deparse.level) {
    # L was created by L<-match.call(expand.dots=FALSE)[[2L]]
    isym <- sapply(L,is.symbol)
    dp <- sapply(L,deparse)
    if (is.null(nm <- names(L))) {
        if (deparse.level==1L) {
            nm<-character(length(L))
            nm[isym] <- dp[isym]
            }
        else
        if (deparse.level==2L) nm <- dp
        }
    else {
        inonm <- nm==""
        i<-isym&inonm
        if (deparse.level==1L) nm[i] <- dp[i]
        if (deparse.level==2L) nm[inonm]<-dp[inonm]
        }
    nm
    }
setGeneric("cbind", function(..., deparse.level=1) standardGeneric("cbind"), signature = c("..."))# -> message about creating generic, signatures differ
setMethod("cbind","mondate_possible", function (..., deparse.level = 0) {
    displayFormat<-mondateDisplayFormat(..1)
    if (is.null(displayFormat<-mondateDisplayFormat(..1))) return(.Internal(cbind(deparse.level, ...)))
    # Default case is fastest.
    if ((timeunits <- mondateTimeunits(..1))=="months")
        new("mondate", .Internal(cbind(deparse.level, ...)), displayFormat=displayFormat, timeunits=timeunits)
    else new("mondate", do.call(base::cbind,c(lapply(structure(list(...), names=.crbindnames(match.call(expand.dots=FALSE)[[2L]], deparse.level=deparse.level)), function(x) getDataPart(mondate(x,timeunits=timeunits))), list(deparse.level=as.integer(deparse.level)))),
             displayFormat=displayFormat, timeunits=timeunits)
    }
    )
setMethod("cbind","mondate_possible_w_date", function (..., deparse.level = 0) {
    displayFormat<-mondateDisplayFormat(..1)
    if (is.null(displayFormat<-mondateDisplayFormat(..1))) return(.Internal(cbind(deparse.level, ...)))
    # When there are dates, must convert column-by-column always
    timeunits<-mondateTimeunits(..1)
    new("mondate", do.call(base::cbind,c(lapply(structure(list(...), names=.crbindnames(match.call(expand.dots=FALSE)[[2L]], deparse.level=deparse.level)), function(x) getDataPart(mondate(x,timeunits=timeunits))), list(deparse.level=as.integer(deparse.level)))),
        displayFormat=displayFormat, timeunits=timeunits)
    }
    )
setMethod("cbind","ANY", function (..., deparse.level = 0) .Internal(cbind(deparse.level, ...)))

setGeneric("rbind", function(..., deparse.level=1) standardGeneric("rbind"), signature = c("..."))# -> message about creating generic, signatures differ
setMethod("rbind","mondate_possible", function (..., deparse.level = 0) {
    displayFormat<-mondateDisplayFormat(..1)
    if (is.null(displayFormat<-mondateDisplayFormat(..1))) return(.Internal(rbind(deparse.level, ...)))
    # Default case is fastest.
    if ((timeunits <- mondateTimeunits(..1))=="months")
        new("mondate", .Internal(rbind(deparse.level, ...)), displayFormat=displayFormat, timeunits=timeunits)
    else new("mondate", do.call(base::rbind,c(lapply(structure(list(...), names=.crbindnames(match.call(expand.dots=FALSE)[[2L]], deparse.level=deparse.level)), function(x) getDataPart(mondate(x,timeunits=timeunits))), list(deparse.level=as.integer(deparse.level)))),
             displayFormat=displayFormat, timeunits=timeunits)
    }
    )
setMethod("rbind","mondate_possible_w_date", function (..., deparse.level = 0) {
    displayFormat<-mondateDisplayFormat(..1)
    if (is.null(displayFormat<-mondateDisplayFormat(..1))) return(.Internal(rbind(deparse.level, ...)))
    # When there are dates, must convert column-by-column always
    timeunits<-mondateTimeunits(..1)
    new("mondate", do.call(base::rbind,c(lapply(structure(list(...), names=.crbindnames(match.call(expand.dots=FALSE)[[2L]], deparse.level=deparse.level)), function(x) getDataPart(mondate(x,timeunits=timeunits))), list(deparse.level=as.integer(deparse.level)))),
        displayFormat=displayFormat, timeunits=timeunits)
    }
    )
setMethod("rbind","ANY", function (..., deparse.level = 0) .Internal(rbind(deparse.level, ...)))

## PRINT, SHOW

setGeneric("print")
setMethod("print", "mondate", function(x, ...) {
    print(noquote(as.character(x)), ...)
    invisible(x)
    })
setMethod("show", "mondate", function(object) {
    cat('mondate: timeunits="', object@timeunits, '"\n', sep="")
    print(noquote(as.character(object)))
    })

## HELPFUL USER FUNCTIONS

## Pulling out month, year, and day numbers
setGeneric("year", function(x, ...) standardGeneric("year"))
setMethod("year", "mondate", function(x, ...) {
    if (is.array(x)) {
        dims <- dim(x)
        dimnams <- dimnames(x)
        y <- as.numeric(format(x, "%Y", ...))
        dim(y) <- dims
        dimnames(y) <- dimnams
        }
    else {
        nams <- names(x)
        y <- as.numeric(format(x, "%Y", ...))
        names(y) <- nams
        }
    y
    })
setGeneric("month", function(x, ...) standardGeneric("month"))
setMethod("month", "mondate", function(x, ...) { 
    if (is.array(x)) {
        dims <- dim(x)
        dimnams <- dimnames(x)
        y <- as.numeric(format(x, "%m", ...))
        dim(y) <- dims
        dimnames(y) <- dimnams
        }
    else {
        nams <- names(x)
        y <- as.numeric(format(x, "%m", ...))
        names(y) <- nams
        }
    y
    })
setGeneric("day", function(x, ...) standardGeneric("day"))
setMethod("day", "mondate", function(x, ...) { 
    if (is.array(x)) {
        dims <- dim(x)
        dimnams <- dimnames(x)
        y <- as.numeric(format(x, "%d", ...))
        dim(y) <- dims
        dimnames(y) <- dimnams
        }
    else {
        nams <- names(x)
        y <- as.numeric(format(x, "%d", ...))
        names(y) <- nams
        }
    y
    })

## Constructing with month, year, and day numbers
mondate.mdy <- function(m,d,y, displayFormat=.default.displayFormat, 
                               timeunits=.default.timeunits, ...) 
    mondate(ISOdate(y,m,d), 
            displayFormat=displayFormat, 
            timeunits=timeunits,
            ...)
mondate.ymd <- function(y,m,d, displayFormat=.default.displayFormat, 
                               timeunits=.default.timeunits, ...) {
    if (missing(d)) d<-.daysinmonth(y,m)
    mondate(ISOdate(y,m,d),
            displayFormat=displayFormat, 
            timeunits=timeunits,
            ...)
    }


## S3 METHODS
##
## The methods in this section are S3 because their S4 implementations
##  displayed resulting mondates as numeric r.t. as dates.

as.data.frame.mondate <- function(x, row.names=NULL, optional=FALSE, ...) {
    dims <- dim(x)
    if (is.null(dims)) nrows <- length(x)
    else
    if (length(dims)==1L) nrows <- length(x)
    else
    if (length(dims)==2L) nrows <- dims[1L]
    else { # flatten like data.frame does
        nrows <- dims[1L]
        dim(x) <- c(dims[1L], length(x)/dims[1L])
        }
    nm <- paste(deparse(substitute(x), width.cutoff = 500), collapse = " ")
    # determine row.names
    if (is.null(row.names)) {
        if (nrows == 0) row.names <- character(0)
        else if(length(row.names <- names(x)) == nrows &&
                !any(duplicated(row.names))) {
            }
        else if(optional) row.names <- character(nrows)
        else row.names <- seq_len(nrows)
        }
    names(x) <- NULL
    value <- list(x)
    if(!optional) names(value) <- nm
    attr(value, "row.names") <- row.names
    class(value) <- "data.frame"
    value
    }

format.mondate<- function(x, ...) as.character(x, ...)

# Now an S4 method
.cbindMondate <- function(..., deparse.level=1) {
    if (is.null(displayFormat<-mondateDisplayFormat(..1))) return(.Internal(cbind(deparse.level, ...)))
    if ((timeunits <- mondateTimeunits(..1))!="months"||any(sapply(match.call(expand.dots=FALSE)[[2L]], function(x) class(eval.parent(x))[1L]) %in% .date.classes))
        new("mondate", do.call(base::cbind,c(lapply(structure(list(...), names=.crbindnames(match.call(expand.dots=FALSE)[[2L]], deparse.level=deparse.level)), function(x) getDataPart(mondate(x,timeunits=timeunits))), list(deparse.level=as.integer(deparse.level)))),
             displayFormat=displayFormat, timeunits=timeunits)
    else new("mondate", .Internal(cbind(deparse.level, ...)), displayFormat=displayFormat, timeunits=timeunits)
    }

.rbindMondate <- function(..., deparse.level=1) {
    if (is.null(displayFormat<-mondateDisplayFormat(..1))) return(.Internal(rbind(deparse.level, ...)))
    if ((timeunits <- mondateTimeunits(..1))!="months"||any(sapply(match.call(expand.dots=FALSE)[[2L]], function(x) class(eval.parent(x))[1L]) %in% .date.classes))
        new("mondate", do.call(base::rbind,c(lapply(structure(list(...), names=.crbindnames(match.call(expand.dots=FALSE)[[2L]], deparse.level=deparse.level)), function(x) getDataPart(mondate(x,timeunits=timeunits))), list(deparse.level=as.integer(deparse.level)))),
             displayFormat=displayFormat, timeunits=timeunits)
    else new("mondate", .Internal(rbind(deparse.level, ...)), displayFormat=displayFormat, timeunits=timeunits)
    }

seq.mondate<-function(from=NULL, to, ...) {
    if (missing(from)) mondate(seq(to=as.numeric(to, convert=TRUE), ...),
            timeunits=to@timeunits,
            displayFormat=to@displayFormat)
    else 
    if (missing(to)) mondate(seq(from=as.numeric(from, convert=TRUE), ...),
                timeunits=from@timeunits,
                displayFormat=from@displayFormat)
    else mondate(seq(from=as.numeric(from, convert=TRUE), to=as.numeric(to, convert=TRUE), ...),
                timeunits=from@timeunits,
                displayFormat=from@displayFormat)
    }

head.mondate <- function(x, ...) {
    if (is.matrix(x)) head.matrix(x, ...) 
    else NextMethod()
    }

tail.mondate <- function(x, ...) {
    if (is.matrix(x)) tail.matrix(x, ...) 
    else NextMethod()
    }