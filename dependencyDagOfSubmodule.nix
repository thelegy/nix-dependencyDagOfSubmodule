lib:
with lib;


let
  assertMultiple = assertions: pipe assertions [
    flatten
    (foldl' (x: y: assert y; x) true)
  ];
in
rec {

  toOrderedList = attrs: let
    nodes = unique (concatLists [
      (attrNames attrs)
      (pipe attrs [(mapAttrsToList (_: x: x.after)) concatLists])
      (pipe attrs [(mapAttrsToList (_: x: x.before)) concatLists])
    ]);
    dependencies = genAttrs nodes (node: unique (concatLists [
      (attrs.${node}.after or [])
      (filter (other: elem node attrs.${other}.before) (attrNames attrs))
    ]));
    partialOrder = x: y: elem x (dependencies.${y} or []);
    orderedNodes = toposort partialOrder nodes;
    orderedList = concatMap (node: toList (attrs.${node} or [])) orderedNodes.result;
    filtedList = filter (x: x.enable) orderedList;
    noLoopAssertion = assertMsg (attrNames orderedNodes == [ "result" ]) "Detected cycle in dependencyDagOfSubmodule: ${generators.toJSON {} orderedNodes}";
    nonReflexivityAssertions = forEach (attrNames attrs) (node: assertMsg (! (partialOrder node node)) "Detected cycle in dependencyDagOfSubmodule: Node \"${node}\" loops onto itself");
    assertions = assertMultiple [
      noLoopAssertion
      nonReflexivityAssertions
    ];
  in assert assertions; filtedList;

  dependencyDagOfSubmodule = module: let

    mod = let
      dagModule.options = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };
        after = mkOption {
          type = types.nonEmptyListOf types.str;
          default = [ "early" ];
        };
        before = mkOption {
          type = types.nonEmptyListOf types.str;
          default = [ "late" ];
        };
      };
    in types.submoduleWith {
      modules = [ module dagModule ];
      shorthandOnlyDefinesConfig = true;
    };

    type = types.attrsOf mod // {
      name = "dependencyDagOfSubmodule";
      description = type.name;
      inherit dependencyDagOfSubmodule toOrderedList;
    };

  in type;

  __functionArgs = {};
  __functor = self: dependencyDagOfSubmodule;

}
