Module:    dfmc-macro-expander
Synopsis:  The pattern match "back-end" functions, calls to which are
           generated by the pattern compiler.
Author:    Keith Playford
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define constant <fragment-list> = <list>;

//// Error handling.

define serious-program-warning <macro-match-error>
  slot condition-macro-name,
    required-init-keyword: macro-name:;
end serious-program-warning;

define serious-program-warning
    <macro-main-rule-match-error> (<macro-match-error>)
  format-string
    "Invalid syntax in %s macro call.";
  format-arguments macro-name;
end serious-program-warning;

define serious-program-warning
    <macro-aux-rule-match-error> (<macro-match-error>)
  slot condition-rule-set-name,
    required-init-keyword: rule-set-name:;
  format-string
    "Invalid syntax for %s in %s macro call.";
  format-arguments rule-set-name, macro-name;
end serious-program-warning;

define serious-program-warning
    <infinite-aux-rule-recursion-match-error> (<macro-match-error>)
  format-string
    "Infinite auxiliary rule recursion in %s macro call - "
    "treating as invalid syntax.";
  format-arguments macro-name;
end serious-program-warning;

define function macro-main-rule-match-error (f*, name)
  note(<macro-main-rule-match-error>,
       source-location: spanning(f*),
       macro-name: name);
end function;

define function macro-aux-rule-match-error (f*, name, set)
  note(<macro-aux-rule-match-error>,
       source-location: spanning(f*),
       macro-name: name,
       rule-set-name: rule-set-name(set));
end function;

//// Body/list destructuring.

// There must be at least one separator in the strict versions.

define function match-body-part (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, first-part :: <fragment-list>)
  let (f*-before, f*-after) = split-at-semicolon(f*);
  values(#f, f*-after | #(), f*-before);
end function;

define function match-body-part-strict (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, first-part :: <fragment-list>)
  let (f*-before, f*-after) = split-at-semicolon(f*);
  if (f*-after)
    values(#f, f*-after, f*-before);
  else
    values(#t, #(), #())
  end;
end function;

define function match-list-part (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, first-part :: <fragment-list>)
  let (f*-before, f*-after) = split-at-comma(f*);
  values(#f, f*-after | #(), f*-before);
end function;

define function match-list-part-strict (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, first-part :: <fragment-list>)
  let (f*-before, f*-after) = split-at-comma(f*);
  if (f*-after)
    values(#f, f*-after, f*-before);
  else
    values(#t, #(), #())
  end;
end function;

// TODO: Change these #t failure indications into objects representing
// the failure. A problem is that we don't really want to have to
// generate these objects as failure occurs since match failure is
// a normal part of matching, and is an unnecessary expense if the
// match fails. I guess the matcher could be re-run to collect this
// information without danger, since the matching process runs no
// user code.

define function match-name (f* :: <fragment-list>, name :: <symbol>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      ~instance?(f, <name-fragment>)
        => values(#t, #());
      fragment-name(f) ~== name
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

define function match-otherwise (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>)
  let (failure, after-f*) = match-name(f*, #"otherwise");
  if (failure)
    values(failure, after-f*);
  else
    if (instance?(after-f*.head, <equal-greater-fragment>))
      values(#f, after-f*.tail);
    else
      values(#f, after-f*);
    end;
  end;
end function;

define function match-operator (f* :: <fragment-list>, name :: <symbol>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      ~instance?(f, <operator-fragment>)
        => values(#t, #());
      fragment-name(f) ~== name
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

define function match-end-of-modifiers (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      ~instance?(f, <end-of-modifiers-marker>)
        => values(#t, #());
      otherwise
        => values(#f, f*.tail);
    end;
  end;
end function;

define function match-equal-greater (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      ~instance?(f, <equal-greater-fragment>)
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

define function match-hash-next (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      object-class(f) ~== <hash-next-fragment>
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

define function match-hash-rest (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      object-class(f) ~== <hash-rest-fragment>
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

define function match-hash-key (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      object-class(f) ~== <hash-key-fragment>
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

define function match-hash-all-keys (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      object-class(f) ~== <hash-all-keys-fragment>
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

define function match-dot (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      object-class(f) ~== <dot-fragment>
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

define function match-colon-colon (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      object-class(f) ~== <colon-colon-fragment>
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

define function match-literal (f* :: <fragment-list>, value :: <object>)
 => (failure, after-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      ~instance?(f, <literal-fragment>)
        => values(#t, #());
      fragment-value(f) ~== value
        => values(#t, #());
      otherwise
        => values(#f, f*.tail)
    end;
  end;
end function;

//// Constraint matching.

define function match-token-constraint (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, parsed :: false-or(<fragment>))
  if (empty?(f*))
    values(#t, #(), #f);
  else
    let f = f*.head;
    case
      instance?(f, <elementary-fragment>)
        => values(#f, f*.tail, f);
      otherwise
        => values(#t, #(), #f);
    end;
  end;
end function;

define function match-name-constraint (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, parsed :: false-or(<fragment>))
  if (empty?(f*))
    values(#t, #(), #f);
  else
    let f = f*.head;
    case
      instance?(f, <name-fragment>)
        => values(#f, f*.tail, f);
      otherwise
        => values(#t, #(), #f);
    end;
  end;
end function;

define function match-expression-constraint (f* :: <fragment-list>)
 => (failure, after-f*, parsed :: false-or(<fragment>))
  if (empty?(f*))
    values(#t, #(), #f);
  else
    let f = f*.head;
    let after-f* = f*.tail;
    if (empty?(after-f*))
      select (f by instance?)
        <name-fragment>, <literal-fragment>, <function-call-fragment>,
        <statement-fragment>, <function-macro-fragment>
          => values(#f, #(), f);
        otherwise
          => parse-constraint($start-expression-constraint, f*);
      end;
    else
      parse-constraint($start-expression-constraint, f*);
    end;
  end;
end function;

define method stop-variable? (f, words) #f end;
define method stop-variable? (f :: <operator-fragment>, x)
  #t
end method;
define method stop-variable? (f :: <comma-fragment>, x)
  #t
end method;

define function match-variable-constraint (f* :: <fragment-list>)
 => (failure, after-f* :: false-or(<fragment-list>), parsed :: false-or(<fragment-list>))
  if (empty?(f*) | ~instance?(f*.head, <name-fragment>))
    // TODO: A hackattack to allow let-bound ellipses for the sake of
    // te procedural macro system. There's a corresponding hack for
    // references in the grammar.
    if (instance?(f*.head, <ellipsis-fragment>))
      let ellipsis = f*.head;
      let name
        = make-variable-name-like
            (ellipsis,
             record:          fragment-record(ellipsis),
             source-position: fragment-source-position(ellipsis),
             name: #"...");
      values(#f, f*.tail, list(name));
    else
      values(#t, #(), #f);
    end;
  else
    let size = size(f*);
    if (size == 3 & f*[1].object-class == <colon-colon-fragment>)
      values(#f, #(), f*);
    elseif (size == 1)
      values(#f, #(), f*);
    else
      parse-bounded-constraint
        ($start-variable-constraint, f*, stop-variable?, #f);
    end;
  end;
end function;

define function match-body-constraint (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, parsed :: false-or(<fragment>))
  if (empty?(f*))
    values(#f, #(), body-fragment(#()));
  else
    let f = f*.head;
    let after-f* = f*.tail;
    if (empty?(after-f*))
      select (f by instance?)
        <macro-call-fragment>, <function-call-fragment>
          => values(#f, #(), body-fragment(list(f)));
        <body-fragment>
          => values(#f, #(), f);
        otherwise
          => parse-constraint($start-body-constraint, f*);
      end;
    else
      parse-constraint($start-body-constraint, f*);
    end;
  end;
end function;

define method stop-body? (f, words) #f end;
define method stop-body? (f :: <name-fragment>, words :: <list>)
  member?(fragment-name(f), words)
end method;

define function match-bounded-body-constraint
    (f* :: <fragment-list>, bounding-words :: <list>)
 => (failure, after-f* :: <fragment-list>, parsed :: false-or(<fragment>))
  if (empty?(f*))
    values(#f, #(), body-fragment(#()));
  else
    let f = f*.head;
    let after-f* = f*.tail;
    if (empty?(after-f*))
      select (f by instance?)
        <macro-call-fragment>, <function-call-fragment>
          => values(#f, #(), body-fragment(list(f)));
        <body-fragment>
          => values(#f, #(), f);
        otherwise
          => parse-bounded-constraint
               ($start-body-constraint, f*, stop-body?, bounding-words);
      end;
    else
      parse-bounded-constraint
        ($start-body-constraint, f*, stop-body?, bounding-words);
    end;
  end;
end function;

define function match-bounded-body-constraint-no-backtracking
    (f* :: <fragment-list>, bounding-words :: <list>)
 => (failure, after-f* :: <fragment-list>, parsed :: false-or(<fragment>))
  if (empty?(f*))
    values(#f, #(), body-fragment(#()));
  else
    let f = f*.head;
    let after-f* = f*.tail;
    if (empty?(after-f*))
      select (f by instance?)
        <macro-call-fragment>, <function-call-fragment>
          => values(#f, #(), body-fragment(list(f)));
        <body-fragment>
          => values(#f, #(), f);
        otherwise
          => parse-bounded-constraint-no-backtracking
               ($start-body-constraint, f*, stop-body?, bounding-words);
      end;
    else
      parse-bounded-constraint-no-backtracking
        ($start-body-constraint, f*, stop-body?, bounding-words);
    end;
  end;
end function;

define function match-case-body-constraint (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, parsed :: false-or(<fragment>))
  parse-constraint($start-case-body-constraint, f*);
end function;

define function match-bounded-case-body-constraint
    (f* :: <fragment-list>, words :: <list>)
 => (failure, after-f* :: <fragment-list>, parsed)
  parse-bounded-constraint
    ($start-case-body-constraint, f*, stop-body?, words);
end function;

define function match-symbol-constraint (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, parsed :: false-or(<fragment>))
  if (empty?(f*))
    values(#t, #());
  else
    let f = f*.head;
    case
      ~instance?(f, <symbol-fragment>)
        => values(#t, #());
      otherwise
        => values(#f, f*.tail, f)
    end;
  end;
end function;

//// Nested matching.

define function match-parens (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, nested-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #(), #());
  else
    let f = f*.head;
    case
      ~instance?(f, <parens-fragment>)
        => values(#t, #(), #());
      otherwise
        => values(#f, f*.tail, fragment-nested-fragments(f));
    end;
  end;
end function;

define function match-brackets (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, nested-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #(), #());
  else
    let f = f*.head;
    case
      ~instance?(f, <brackets-fragment>)
        => values(#t, #(), #());
      otherwise
        => values(#f, f*.tail, fragment-nested-fragments(f));
    end;
  end;
end function;

define function match-braces (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, nested-f* :: <fragment-list>)
  if (empty?(f*))
    values(#t, #(), #());
  else
    let f = f*.head;
    case
      ~instance?(f, <braces-fragment>)
        => values(#t, #(), #());
      otherwise
        => values(#f, f*.tail, fragment-nested-fragments(f));
    end;
  end;
end function;

//// Structured matching.

// TODO: Eliminate this unnecessary list consing.

define function match-variable (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>,
       name :: <fragment-list>, type :: <fragment-list>)
  let (failure, after-f*, parsed) = match-variable-constraint(f*);
  if (failure)
    values(failure, #(), #(), #());
  else
    values
      (#f, after-f*,
       list(parsed.head),
       if (empty?(parsed.tail))
         list(dylan-variable-name(#"<object>"))
       else
         list(parsed[2]);
       end);
  end;
end function;

define function match-spliced-name
    (f* :: <fragment-list>,
       prefix :: false-or(<string>), suffix :: false-or(<string>))
 => (failure, after-f* :: <fragment-list>, name :: type-union(<variable-name-fragment>, <list>))
  block (return)
    let (failure, after-f*, parsed) = match-name-constraint(f*);
    if (failure)
      values(failure, #(), #(), #());
    else
      // Check that the name matches the prefix and suffix, if any.
      let name = as(<string>, fragment-name(parsed));
      let start-pos
        = if (prefix)
            if (matching-prefix?(name, prefix))
              prefix.size
            else
              return
                ("Name doesn't have a matching prefix", #(), #(), #());
            end
          else
            0
          end;
      let end-pos
        = if (suffix)
            if (matching-suffix?(name, suffix))
              name.size - suffix.size
            else
              return
                ("Name doesn't have a matching suffix", #(), #(), #());
            end
          else
            name.size
          end;
      let core-name = copy-sequence(name, start: start-pos, end: end-pos);
      // TODO: Subset the source location so that only the bound range of
      // characters is recorded.
      let parsed-name
        = make-variable-name-like
            (parsed,
             record:          fragment-record(parsed),
             source-position: fragment-source-position(parsed),
             name:            as(<symbol>, core-name));
      values(#f, after-f*, parsed-name);
    end;
  end;
end function;

define function matching-prefix?
    (name :: <string>, prefix :: <string>) => (well? :: <boolean>)
  if (size(name) < size(prefix))
    #f
  else
    block (return)
      for (name-c in name, prefix-c in prefix)
        if (~any-case-equal?(name-c, prefix-c))
          return(#f);
        end;
      finally
        #t
      end;
    end;
  end;
end function;

define function matching-suffix?
    (name :: <string>, suffix :: <string>) => (well? :: <boolean>)
  if (size(name) < size(suffix))
    #f
  else
    block (return)
      for (name-c   in name   using backward-iteration-protocol,
           suffix-c in suffix using backward-iteration-protocol)
        if (~any-case-equal?(name-c, suffix-c))
          return(#f);
        end;
      finally
        #t
      end;
    end;
  end;
end function;

// If the rest constraint is #f, no rest value need be bound.
// A key-spec is a symbol, constraint, default thunk triple.

define function match-property-list
    (f* :: <fragment-list>, rest-constraint, #rest key-specs)
 => (failure, f*, rest, #rest keys)
  let (failure, remains, parsed)
    = parse-constraint($start-property-list-constraint, f*);
  if (failure)
    values(failure, remains, #f);
  elseif (~empty?(remains))
    values("More fragments appear after the property list", remains, #f);
  else
    collecting (key-values, missing-keys)
      // TODO: PERFORMANCE: Remove this list coercion.
      for (cursor = as(<list>, key-specs) then cursor.tail.tail.tail,
             until: cursor == #())
        let symbol = cursor[0];
        let constraint = cursor[1];
        let default-thunk = cursor[2];
        if (instance?(constraint, <list>))
          let arg-val = property-list-elements(parsed, symbol);
          if (arg-val ~== #())
            collect-into(key-values, arg-val);
          elseif (default-thunk)
            collect-into(key-values, list(default-thunk()));
          else
            collect-into(key-values, #());
          end;
        else
          let arg-val = property-list-element(parsed, symbol);
          if (arg-val)
            collect-into(key-values, arg-val);
          else
            if (default-thunk)
              collect-into(key-values, default-thunk());
            else
              collect-into(missing-keys, symbol);
            end;
          end;
        end;
      end;
      let missing-keys = collected(missing-keys);
      if (missing-keys == #())
        apply(values, #f, #(), parsed, collected(key-values));
      else
        values("missing keyword option", #(), #f);
      end;
    end;
  end;
end function;

define function property-list-element
    (plist :: <list>, symbol :: <symbol>)
  iterate walk (cursor = plist)
    if (cursor == #())
      #f
    elseif (fragment-value(cursor.head) == symbol)
      split-at-comma(cursor.tail);
    else
      walk(skip-to-comma(cursor.tail));
    end;
  end;
end function;

define function property-list-elements
    (plist :: <list>, symbol :: <symbol>)
  collecting ()
    iterate walk (cursor = plist)
      if (cursor == #())
        #f
      elseif (fragment-value(cursor.head) == symbol)
        let (value, next) = split-at-comma(cursor.tail);
        collect(value);
        if (next) walk(next) end;
      else
        walk(skip-to-comma(cursor.tail));
      end;
    end;
  end;
end function;

define function match-macro-constraint
    (f* :: <fragment-list>)
 => (failure, after-f* :: <fragment-list>, expansion)
  if (empty?(f*) | ~instance?(f*.head, <macro-call-fragment>))
    values("Macro expected, but not provided", #(), #f);
  else
    values(#f, f*.tail, expand-for-macro-constraint(f*.head));
  end;
end function;

// This is implemented in the compiler proper.

define compiler-open generic expand-for-macro-constraint
    (call :: <macro-call-fragment>) => (expansion);

// TODO: PERFORMANCE: Use come kind of case insensitive string compare
// primitive perhaps.

define function any-case-equal?
    (c1 :: <character>, c2 :: <character>) => (boolean)
  as-lowercase(c1) == as-lowercase(c2)
end function;

//// Utils.

define function split-at-semicolon
    (l :: <list>) => (left :: <list>, right :: false-or(<list>))
  local method split (l)
    case
      l == #()
        => values(#(), #f);
      l.head.object-class == <semicolon-fragment>
        => values(#(), l.tail);
      otherwise
        => let (left, right) = split(l.tail);
           values(pair(l.head, left), right);
    end;
  end;
  split(l);
end function;

define function split-at-kept-semicolon
    (l :: <list>) => (left :: <list>, right :: false-or(<list>))
  local method split (l)
    case
      l == #()
        => values(#(), #f);
      l.head.object-class == <semicolon-fragment>
        => values(#(), l);
      otherwise
        => let (left, right) = split(l.tail);
           values(pair(l.head, left), right);
    end;
  end;
  split(l);
end function;

define function split-at-semicolons (l :: <list>)
  collecting (parts)
    local method walk (l, count)
      let (left, right) = split-at-semicolon(l);
      collect-into(parts, left);
      if (right)
        walk(right, count + 1)
      else
        values(collected(parts), count);
      end;
    end;
    walk(l, 1);
  end;
end function;

define function skip-to-comma
    (l :: <list>) => (after :: <list>)
  local method split (l)
    case
      l == #()
        => #();
      l.head.object-class == <comma-fragment>
        => l.tail;
      otherwise
        => split(l.tail);
    end;
  end;
  split(l);
end function;

define function split-at-comma
    (l :: <list>) => (left :: <list>, right :: false-or(<list>))
  local method split (l)
    case
      l == #()
        => values(#(), #f);
      l.head.object-class == <comma-fragment>
        => values(#(), l.tail);
      otherwise
        => let (left, right) = split(l.tail);
           values(pair(l.head, left), right);
    end;
  end;
  split(l);
end function;

define function split-at-commas (l :: <list>)
  collecting (parts)
    local method walk (l, count)
      let (left, right) = split-at-comma(l);
      collect-into(parts, left);
      if (right)
        walk(right, count + 1)
      else
        values(collected(parts), count);
      end;
    end;
    walk(l, 1);
  end;
end function;
