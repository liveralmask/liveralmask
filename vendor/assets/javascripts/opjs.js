var opjs = this;

/* Pure JavaScripts */

opjs.is_undef = function( value ){
  return ( typeof value === "undefined" );
};

opjs.is_def = function( value ){
  return ! opjs.is_undef( value );
};

opjs.is_string = function( value ){
  return ( typeof value === "string" );
};

opjs.is_array = function( value ){
  return ( value instanceof Array );
};

opjs.is_kvary = function( value ){
  return ( typeof value === "object" );
};

(function( array ){
  array.each = function( values, callback ){
    var values_len = values.length;
    for ( var i = 0; i < values_len; ++i ){
      if ( false === callback( values[ i ], i ) ) break;
    }
  };
})(opjs.array = opjs.array || {});

(function( vars ){
  var s_vars = {};
  
  vars.set = function( key, value ){
    s_vars[ key ] = value;
  };
  
  vars.get = function( key ){
    return s_vars[ key ];
  };
})(opjs.vars = opjs.vars || {});

(function( string ){
  string.format = function(){
    var args = Array.prototype.slice.call( arguments );
    var head = "";
    var tail = args.shift();
    if ( opjs.is_kvary( args[ 0 ] ) ) args = args[ 0 ];
    var pattern = new opjs.Pattern( undefined, "\{([a-zA-Z0-9_]+)\}" );
    while ( "" !== tail ){
      var match = pattern.match( tail );
      if ( null === match ) break;
      
      var key = match.matches[ 1 ];
      head += ( key in args ) ? match.head + args[ key ] : match.matches[ 0 ];
      tail = match.tail;
    }
    return head + tail;
  };
  
  string.multi = function( value, count ){
    var array = [];
    for ( var i = 0; i < count; ++i ){
      array.push( value );
    }
    return array.join( "" );
  };
  
  string.padding_zero = function( digit, value ){
    return ( string.multi( "0", digit ) + value ).slice( - digit );
  };
})(opjs.string = opjs.string || {});

opjs.Pattern = function( value, pattern, flags ){
  this.m_value = value;
  this.m_regex = new RegExp( pattern, flags );
};
opjs.Pattern.prototype.match = function( value ){
  var matches = this.m_regex.exec( value );
  return ( null === matches ) ? null : { "value" : this.m_value, "matches" : matches, "head" : RegExp.leftContext, "tail" : RegExp.rightContext };
};

(function( pattern ){
  var s_patterns = {};
  
  pattern.add = function( type, name, pattern, flags ){
    var add_value = new opjs.Pattern( name, pattern, flags );
    if ( type in s_patterns ){
      s_patterns[ type ].push( add_value );
    }else{
      s_patterns[ type ] = [ add_value ];
    }
  };
  
  pattern.match = function( type, value ){
    if ( opjs.is_undef( s_patterns[ type ] ) ) return null;
    
    var result = null;
    opjs.array.each( s_patterns[ type ], function( _pattern, i ){
      result = _pattern.match( value );
      if ( null !== result ) return false;
    });
    return result;
  };
  
  pattern.matches = function( type, value ){
    if ( opjs.is_undef( s_patterns[ type ] ) ) return [];
    
    var matches = [];
    opjs.array.each( s_patterns[ type ], function( _pattern, i ){
      var result = _pattern.match( value );
      if ( null !== result ) matches.push( result );
    });
    return matches;
  };
})(opjs.pattern = opjs.pattern || {});

(function( json ){
  json.encode = function( value ){
    return JSON.stringify( value );
  };
  
  json.decode = function( value ){
    var pattern = new opjs.Pattern( undefined, "([0-9]{4})/([0-9]{2})/([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2}).([0-9]{3})" );
    return JSON.parse( value, function( k, v ){
      var match = pattern.match( v );
      return ( null === match ) ? v : opjs.time.local_time.apply( opjs.time, match.matches.slice( 1 ) );
    });
  };
})(opjs.json = opjs.json || {});

(function( time ){
  time.LocalTime = function( year, month, date, hour, min, sec, msec ){
    if ( opjs.is_undef( month ) ) month = 1;
    if ( opjs.is_undef( date ) ) date = 1;
    if ( opjs.is_undef( hour ) ) hour = 0;
    if ( opjs.is_undef( min ) )  min = 0;
    if ( opjs.is_undef( sec ) )  sec = 0;
    if ( opjs.is_undef( msec ) ) msec = 0;
    
    this.m_value = ( opjs.is_undef( year ) ) ? new Date() : new Date( year, month - 1, date, hour, min, sec, msec );
  };
  time.LocalTime.prototype.value = function(){
    return this.m_value;
  };
  time.LocalTime.prototype.year = function(){
    return this.m_value.getFullYear();
  };
  time.LocalTime.prototype.month = function(){
    return this.m_value.getMonth() + 1;
  };
  time.LocalTime.prototype.date = function(){
    return this.m_value.getDate();
  };
  time.LocalTime.prototype.day = function(){
    return this.m_value.getDay();
  };
  time.LocalTime.prototype.hour = function(){
    return this.m_value.getHours();
  };
  time.LocalTime.prototype.min = function(){
    return this.m_value.getMinutes();
  };
  time.LocalTime.prototype.sec = function(){
    return this.m_value.getSeconds();
  };
  time.LocalTime.prototype.msec = function(){
    return this.m_value.getMilliseconds();
  };
  time.LocalTime.prototype.toString = function(){
    return time.format( "all", this );
  };
  time.LocalTime.prototype.toJSON = function(){
    return this.toString();
  };
  time.LocalTime.prototype.is_same_date = function( local_time ){
    if ( this.date()  != local_time.date() )  return false;
    if ( this.month() != local_time.month() ) return false;
    if ( this.year()  != local_time.year() )  return false;
    return true;
  };
  
  time.MeasureTime = function(){
    this.start();
  };
  time.MeasureTime.prototype.start = function(){
    this.m_start_time = new time.LocalTime();
    this.m_end_time = this.m_start_time;
    this.m_count = 0;
  };
  time.MeasureTime.prototype.update = function(){
    this.m_end_time = new time.LocalTime();
    this.m_count += 1;
    return this.m_end_time.value() - this.m_start_time.value();
  };
  time.MeasureTime.prototype.count = function(){
    return this.m_count;
  };
  
  time.local_time = function( year, month, date, hour, min, sec, msec ){
    return new time.LocalTime( year, month, date, hour, min, sec, msec );
  };
  
  time.first_date_time = function( year, month ){
    return time.local_time( year, month, 1 );
  };
  
  time.last_date_time = function( year, month ){
    return time.local_time( year, month + 1, 0 );
  };
  
  time.format = function( type, local_time ){
    if ( opjs.is_undef( local_time ) ) local_time = time.local_time();
    
    var value = "";
    switch ( type ){
    case "all":{
      value = opjs.string.format( "{0}/{1}/{2} {3}:{4}:{5}.{6}",
        local_time.year(),
        opjs.string.padding_zero( 2, local_time.month() ),
        opjs.string.padding_zero( 2, local_time.date() ),
        opjs.string.padding_zero( 2, local_time.hour() ),
        opjs.string.padding_zero( 2, local_time.min() ),
        opjs.string.padding_zero( 2, local_time.sec() ),
        opjs.string.padding_zero( 3, local_time.msec() ) );
    }break;
    
    case "ymdhms":{
      value = opjs.string.format( "{0}/{1}/{2} {3}:{4}:{5}",
        local_time.year(),
        opjs.string.padding_zero( 2, local_time.month() ),
        opjs.string.padding_zero( 2, local_time.date() ),
        opjs.string.padding_zero( 2, local_time.hour() ),
        opjs.string.padding_zero( 2, local_time.min() ),
        opjs.string.padding_zero( 2, local_time.sec() ) );
    }break;
    
    case "ymdhm":{
      value = opjs.string.format( "{0}/{1}/{2} {3}:{4}",
        local_time.year(),
        opjs.string.padding_zero( 2, local_time.month() ),
        opjs.string.padding_zero( 2, local_time.date() ),
        opjs.string.padding_zero( 2, local_time.hour() ),
        opjs.string.padding_zero( 2, local_time.min() ) );
    }break;
    
    case "ymd":{
      value = opjs.string.format( "{0}/{1}/{2}",
        local_time.year(),
        opjs.string.padding_zero( 2, local_time.month() ),
        opjs.string.padding_zero( 2, local_time.date() ) );
    }break;
    
    case "YMD":{
      value = opjs.string.format( "{0}{1}{2}",
        local_time.year(),
        opjs.string.padding_zero( 2, local_time.month() ),
        opjs.string.padding_zero( 2, local_time.date() ) );
    }break;
    
    case "hms":{
      value = opjs.string.format( "{0}:{1}:{2}",
        opjs.string.padding_zero( 2, local_time.hour() ),
        opjs.string.padding_zero( 2, local_time.min() ),
        opjs.string.padding_zero( 2, local_time.sec() ) );
    }break;
    
    case "HMS":{
      value = opjs.string.format( "{0}{1}{2}",
        opjs.string.padding_zero( 2, local_time.hour() ),
        opjs.string.padding_zero( 2, local_time.min() ),
        opjs.string.padding_zero( 2, local_time.sec() ) );
    }break;
    
    case "hm":{
      value = opjs.string.format( "{0}:{1}",
        opjs.string.padding_zero( 2, local_time.hour() ),
        opjs.string.padding_zero( 2, local_time.min() ) );
    }break;
    
    case "HM":{
      value = opjs.string.format( "{0}{1}",
        opjs.string.padding_zero( 2, local_time.hour() ),
        opjs.string.padding_zero( 2, local_time.min() ) );
    }break;
    }
    return value;
  };
  
  time.string_days = function(){
    return [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ];
  };
  
  time.holiday = function( year, month, date, day, holidays ){
    if ( opjs.is_undef( holidays ) ) holidays = {};
    
    do{
      if ( ! ( year in holidays ) ) break;
      if ( ! ( month in holidays[ year ] ) ) break;
      if ( ! ( date in holidays[ year ][ month ] ) ) break;
      return holidays[ year ][ month ][ date ];
    }while ( false );
    return "";
  };
  
  time.date = function( year, month, date, day, holidays ){
    return {
      "year"    : year,
      "month"   : month,
      "date"    : date,
      "day"     : day,
      "holiday" : opjs.time.holiday( year, month, date, ( "index" in day ) ? day.index : day, holidays ),
    };
  };
  
  time.dates = function( year, month, string_days ){
    if ( opjs.is_undef( string_days ) ) string_days = time.string_days();
    
    var dates = [];
    var first_date_time = time.first_date_time( year, month );
    var last_date_time = time.last_date_time( year, month );
    var last_date = last_date_time.date();
    var day = first_date_time.day();
    for ( var date = 1; date <= last_date; ++date, day = time.add_day( day ) ){
      dates.push({ "date" : date, "day" : { "index" : day, "string" : string_days[ day ] } });
    }
    return dates;
  };
  
  time.add_day = function( base, add ){
    if ( opjs.is_undef( add ) ) add = 1;
    
    return ( base + add ) % 7;
  };
})(opjs.time = opjs.time || {});

(function( method ){
  method.call = function(){
    var args = Array.prototype.slice.call( arguments );
    var instance = args.shift();
    var method_names = args.shift().split( "." );
    var method = instance;
    opjs.array.each( method_names, function( method_name, i ){
      method = method[ method_name ];
      if ( opjs.is_undef( method ) ) return undefined;
    });
    return method.apply( instance, args );
  };
})(opjs.method = opjs.method || {});

(function( object ){
  object.inherits = function( self, parent ){
    var keys = Object.keys( parent );
    var keys_len = keys.length;
    opjs.array.each( keys, function( key, i ){
      self[ key ] = parent[ key ];
    });
    if ( 0 === keys_len ) self.prototype = new parent();
  };
})(opjs.object = opjs.object || {});

opjs.Application = function(){
  this.m_is_update = false;
  this.m_request = {};
  this.m_response = {};
};
opjs.Application.prototype.is_update = function(){
  if ( 1 == arguments.length ) this.m_is_update = arguments[ 0 ];
  return this.m_is_update;
};
opjs.Application.prototype.request = function(){
  if ( 1 == arguments.length ) this.m_request = arguments[ 0 ];
  return this.m_request;
};
opjs.Application.prototype.response = function(){
  if ( 1 == arguments.length ) this.m_response = arguments[ 0 ];
  return this.m_response;
};
opjs.Application.prototype.start = function(){};
opjs.Application.prototype.update = function(){};
opjs.Application.prototype.end = function(){};

(function( application ){
  application.run = function( application_type, request ){
    if ( opjs.is_undef( request ) ) request = {};
    
    var _application = null;
    try{
      _application = new application_type();
      _application.request( request );
      _application.start();
      if ( _application.is_update() ) _application.update();
      _application.end();
    }catch ( err ){
      opjs.log.err( opjs.string.format( "{0}\n{1}\n{2}", err.toString(), err.stack, opjs.json.encode( request ) ) );
    }
    return ( null !== _application ) ? _application.response() : {};
  };
  
  application.rules_to_array = function( rules, title ){
    var array = ( opjs.is_undef( title ) ) ? [] : [ title ];
    opjs.array.each( rules, function( rule, i ){
      array.push( opjs.string.format( "{0} /{1}/{2}", rule.name, rule.pattern, rule.flags ) );
    });
    return array;
  };
})(opjs.application = opjs.application || {});

opjs.Log = function(){
  
};
opjs.Log.prototype.write = function( type, msg ){};

(function( log ){
  var s_log = null;
  log.set = function( value ){
    s_log = value;
    return s_log;
  };
  log.get = function(){
    return s_log;
  };
  
  log.timestamp = function( local_time ){
    if ( opjs.is_undef( local_time ) ) local_time = opjs.time.local_time();
    
    return opjs.string.format( "[{0}]", opjs.time.format( "all", local_time ) );
  };
  
  log.write = function( type, msg ){
    if ( null !== s_log ) s_log.write( type, msg );
  };
  
  log.dbg = function(){
    var msg = opjs.string.format.apply( null, Array.prototype.slice.call( arguments ) );
    log.write( "dbg", msg );
  };
  
  log.inf = function(){
    var msg = opjs.string.format.apply( null, Array.prototype.slice.call( arguments ) );
    log.write( "inf", msg );
  };
  
  log.wrn = function(){
    var msg = opjs.string.format.apply( null, Array.prototype.slice.call( arguments ) );
    log.write( "wrn", msg );
  };
  
  log.err = function(){
    var msg = opjs.string.format.apply( null, Array.prototype.slice.call( arguments ) );
    log.write( "err", msg );
  };
})(opjs.log = opjs.log || {});

(function( document ){
  var s_document = null;
  document.set = function( value ){
    s_document = value;
    return s_document;
  };
  document.get = function(){
    return s_document;
  };
  
  document.html_to_text = function( value ){
    var head = "";
    var tail = value;
    var pattern = new opjs.Pattern( undefined, "([&'`\"<>])" );
    while ( "" !== tail ){
      var match = pattern.match( tail );
      if ( null === match ) break;
      
      head += match.head;
      switch ( match.matches[ 1 ] ){
      case '&': head += "&amp;";  break;
      case "'": head += "&#x27;"; break;
      case '`': head += "&#x60;"; break;
      case '"': head += "&quot;"; break;
      case '<': head += "&lt;";   break;
      case '>': head += "&gt;";   break;
      }
      tail = match.tail;
    }
    return head + tail;
  };
})(opjs.document = opjs.document || {});

(function( event ){
  event.add = function( target, name, callback ){
    target.addEventListener( name, callback );
  };
})(opjs.document.event = opjs.document.event || {});

(function( element ){
  element.create = function( tag_name, attributes, values ){
    if ( opjs.is_undef( attributes ) ) attributes = {};
    if ( opjs.is_undef( values ) ) values = {};
    
    var _element = opjs.document.get().createElement( tag_name );
    var attr_keys = Object.keys( attributes );
    opjs.array.each( attr_keys, function( attr_key, i ){
      element.attr( _element, attr_key, attributes[ attr_key ] );
    });
    if ( "text" in values ){
      element.text( _element, values.text );
    }else if ( "html" in values ){
      element.html( _element, values.html );
    }
    return _element;
  };
  
  element.attr = function(){
    var args = Array.prototype.slice.call( arguments );
    var _element = args.shift();
    var key = args.shift();
    var value = "";
    switch ( key ){
    case "readonly":{
      if ( 1 == args.length ) _element.readOnly = args[ 0 ];
      value = _element.readOnly;
    }break;
    
    default:{
      if ( 1 == args.length ) _element.setAttribute( key, args[ 0 ] );
      value = _element.getAttribute( key );
    }break;
    }
    return value;
  };
  
  element.style = function(){
    var args = Array.prototype.slice.call( arguments );
    var _element = args.shift();
    var key = args.shift();
    if ( 1 == args.length ) _element.style[ key ] = args[ 0 ];
    return _element.style[ key ];
  };
  
  element.text = function(){
    var args = Array.prototype.slice.call( arguments );
    var _element = args.shift();
    if ( 1 == args.length ) _element.textContent = args[ 0 ];
    return _element.textContent;
  };
  
  element.html = function(){
    var args = Array.prototype.slice.call( arguments );
    var _element = args.shift();
    if ( 1 == args.length ) _element.innerHTML = args[ 0 ];
    return _element.innerHTML;
  };
  
  element.get = function( id ){
    return opjs.document.get().getElementById( id );
  };
  
  element.gets = function( name ){
    return opjs.document.get().getElementsByName( name );
  };
  
  element.tags = function( name ){
    return opjs.document.get().getElementsByTagName( name );
  };
  
  element.add = function( parent, child ){
    parent.appendChild( child );
  };
  
  element.insert = function( parent, before, after ){
    parent.insertBefore( after, before );
  };
  
  element.remove = function( parent, child ){
    parent.removeChild( child );
  };
  
  element.removes = function( parent ){
    while ( parent.firstChild ){
      parent.removeChild( parent.firstChild );
    }
  };
  
  element.thead = function( values, attributes ){
    var thead = element.create( "thead" );
    var tr = element.create( "tr" );
    opjs.array.each( values, function( value, i ){
      element.add( tr, element.create( "th", attributes, { "text" : value } ) );
    });
    element.add( thead, tr );
    return thead;
  };
  
  element.tfoot = function( values, attributes ){
    var tfoot = element.create( "tfoot" );
    var tr = element.create( "tr" );
    opjs.array.each( values, function( value, i ){
      element.add( tr, element.create( "td", attributes, { "text" : values[ i ] } ) );
    });
    element.add( tfoot, tr );
    return tfoot;
  };
  
  element.tbody = function( values, attributes ){
    var tbody = element.create( "tbody" );
    opjs.array.each( values, function( value, value_i ){
      var tr = element.create( "tr" );
      var tds = element.tds( value, attributes );
      opjs.array.each( tds, function( td, td_i ){
        element.add( tr, td );
      });
      element.add( tbody, tr );
    });
    return tbody;
  };
  
  element.tds = function( value, attributes ){
    var tds = [];
    opjs.array.each( ( value instanceof Array ) ? value : [ value ], function( data, i ){
      var td = element.create( "td", attributes );
      if ( "text" in data ){
        element.text( td, data.text );
      }else if ( "html" in data ){
        element.html( td, data.html );
      }
      if ( "attributes" in data ){
        var attr_keys = Object.keys( data.attributes );
        opjs.array.each( attr_keys, function( attr_key, i ){
          element.attr( td, attr_key, opjs.string.format( "{0};{1}", element.attr( td, attr_key ), data.attributes[ attr_key ] ) );
        });
      }
      tds.push( td );
    });
    return tds;
  };
  
  element.array_to_table = function( body, head, foot, attributes ){
    if ( opjs.is_undef( attributes ) ){
      attributes = {};
    }
    var table = element.create( "table", attributes.table );
    
    if ( opjs.is_def( head ) ){
      element.add( table, opjs.document.element.thead( head, attributes.head ) );
    }
    
    if ( opjs.is_def( foot ) ){
      element.add( table, opjs.document.element.tfoot( foot, attributes.foot ) );
    }
    
    element.add( table, opjs.document.element.tbody( body, attributes.body ) );
    return table;
  };
})(opjs.document.element = opjs.document.element || {});

(function( xpath ){
  xpath.iterators = function( expression, root ){
    try{
      if ( opjs.is_undef( root ) ) root = opjs.document.get();
      return opjs.document.get().evaluate( expression, root, null, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null );
    }catch ( err ){
      return { "msg" : err.toString(), "stack" : err.stack };
    }
  };
})(opjs.document.xpath = opjs.document.xpath || {});

(function( stack ){
  stack.get = function( offset ){
    if ( opjs.is_undef( offset ) ) offset = 0;
    
    var stacks = [];
    try{
      throw new Error();
    }catch ( err ){
      stacks = err.stack.split( "\n" );
      stacks.shift();
      stacks = stacks.slice( offset );
    }
    return stacks.join( "\n" );
  };
})(opjs.stack = opjs.stack || {});
