function test_suite = test_issue_2
    test_suite = functiontests(localfunctions);
end

function test_open_parent_table(testCase)
    % Test case: valid/array/open-parent-table
    % Array-of-tables defined before explicit parent table
    toml_str = sprintf(['[[parent-table.arr]]\n' ...
                       '[[parent-table.arr]]\n' ...
                       '[parent-table]\n' ...
                       'not-arr = 1']);
    
    result = toml.decode(toml_str);
    
    % Verify structure
    testCase.verifyClass(result, 'containers.Map');
    testCase.verifyTrue(isKey(result, 'parent-table'));
    
    % Verify parent-table is a Map
    parent_tbl = result('parent-table');
    testCase.verifyClass(parent_tbl, 'containers.Map');
    
    % Verify not-arr key exists and has correct value
    testCase.verifyTrue(isKey(parent_tbl, 'not-arr'));
    testCase.verifyEqual(parent_tbl('not-arr'), 1);
    
    % Verify arr is an array of tables (cell)
    testCase.verifyTrue(isKey(parent_tbl, 'arr'));
    testCase.verifyClass(parent_tbl('arr'), 'cell');
    testCase.verifyEqual(length(parent_tbl('arr')), 2);
end

function test_table_9(testCase)
    % Test case: valid/spec-1.0.0/table-9
    % Dotted keys before sub-table definition
    toml_str = sprintf(['[fruit]\n' ...
                       'apple.color = "red"\n' ...
                       'apple.taste.sweet = true\n' ...
                       '[fruit.apple.texture]\n' ...
                       'smooth = true']);
    
    result = toml.decode(toml_str);
    
    % Verify structure
    testCase.verifyTrue(isKey(result, 'fruit'));
    fruit = result('fruit');
    testCase.verifyClass(fruit, 'containers.Map');
    
    % Verify apple table
    testCase.verifyTrue(isKey(fruit, 'apple'));
    apple = fruit('apple');
    testCase.verifyClass(apple, 'containers.Map');
    
    % Verify color
    testCase.verifyTrue(isKey(apple, 'color'));
    testCase.verifyEqual(apple('color'), "red");
    
    % Verify taste
    testCase.verifyTrue(isKey(apple, 'taste'));
    taste = apple('taste');
    testCase.verifyClass(taste, 'containers.Map');
    testCase.verifyTrue(isKey(taste, 'sweet'));
    testCase.verifyEqual(taste('sweet'), true);
    
    % Verify texture (added via sub-table)
    testCase.verifyTrue(isKey(apple, 'texture'));
    texture = apple('texture');
    testCase.verifyClass(texture, 'containers.Map');
    testCase.verifyTrue(isKey(texture, 'smooth'));
    testCase.verifyEqual(texture('smooth'), true);
end

function test_array_within_dotted(testCase)
    % Test case: valid/table/array-within-dotted
    % Array-of-tables within dotted key paths
    toml_str = sprintf(['[fruit]\n' ...
                       'apple.color = "red"\n' ...
                       '[[fruit.apple.seeds]]\n' ...
                       'size = 2']);
    
    result = toml.decode(toml_str);
    
    % Verify structure
    testCase.verifyTrue(isKey(result, 'fruit'));
    fruit = result('fruit');
    testCase.verifyClass(fruit, 'containers.Map');
    
    % Verify apple
    testCase.verifyTrue(isKey(fruit, 'apple'));
    apple = fruit('apple');
    testCase.verifyClass(apple, 'containers.Map');
    
    % Verify color
    testCase.verifyTrue(isKey(apple, 'color'));
    testCase.verifyEqual(apple('color'), "red");
    
    % Verify seeds array
    testCase.verifyTrue(isKey(apple, 'seeds'));
    seeds = apple('seeds');
    testCase.verifyClass(seeds, 'cell');
    testCase.verifyEqual(length(seeds), 1);
    
    % Verify first seed entry
    seed = seeds{1};
    testCase.verifyClass(seed, 'containers.Map');
    testCase.verifyTrue(isKey(seed, 'size'));
    testCase.verifyEqual(seed('size'), 2);
end
