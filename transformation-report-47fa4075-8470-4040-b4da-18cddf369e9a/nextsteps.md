# Next Steps

## 1. Verify Project Configuration

### Review Target Framework
- Open each `.csproj` file and confirm the `<TargetFramework>` is set appropriately (e.g., `net6.0`, `net7.0`, or `net8.0`)
- Ensure all projects in the solution target compatible framework versions
- Check for any remaining .NET Framework references that may need updating

### Validate NuGet Package References
- Review all `<PackageReference>` entries in your project files
- Ensure all packages have been updated to versions compatible with .NET (not .NET Framework)
- Look for packages with deprecated dependencies and update them to modern alternatives
- Run `dotnet list package --outdated` to identify packages that can be updated

## 2. Runtime Testing

### Functional Testing
- Execute your existing unit test suite: `dotnet test`
- Review test results and investigate any failures
- Pay special attention to tests involving:
  - File I/O operations (path separators differ between Windows and Unix-based systems)
  - Configuration loading (ensure `appsettings.json` and other config files are copied to output)
  - Database connections (verify connection strings work cross-platform)
  - Date/time operations (timezone handling may differ)

### Manual Application Testing
- Run the application locally: `dotnet run --project <YourMainProject>`
- Test critical user workflows end-to-end
- Verify all features work as expected
- Check logging output for warnings or errors

## 3. Cross-Platform Validation

### Test on Multiple Operating Systems
If your goal is true cross-platform support:
- Test on Windows (if not already your development environment)
- Test on Linux (Ubuntu or your target distribution)
- Test on macOS (if applicable to your use case)

### Path and File System Considerations
- Search your codebase for hardcoded path separators (`\` or `/`)
- Replace with `Path.Combine()` or `Path.DirectorySeparatorChar`
- Verify file permissions are handled correctly on Unix-based systems

## 4. Configuration and Dependencies

### Application Configuration
- Verify `appsettings.json` and environment-specific configuration files are present
- Ensure configuration transformations work correctly
- Test environment variable substitution if used

### External Dependencies
- Verify connections to databases, APIs, and external services
- Test authentication mechanisms (Windows Authentication may need alternatives)
- Confirm third-party service integrations function correctly

## 5. Performance and Compatibility Review

### Code Analysis
- Run `dotnet build -warnaserror` to identify any warnings that should be addressed
- Use code analyzers to identify potential issues: `dotnet format --verify-no-changes`
- Review any obsolete API warnings and update to recommended alternatives

### Platform-Specific Code
- Search for `#if NETFRAMEWORK` or similar conditional compilation directives
- Verify platform-specific code paths are still necessary or can be simplified
- Check for P/Invoke calls that may need platform-specific implementations

## 6. Prepare for Deployment

### Build Verification
- Perform a clean build: `dotnet clean` followed by `dotnet build`
- Build in Release configuration: `dotnet build -c Release`
- Verify all projects build successfully without warnings

### Publishing
- Test the publish process: `dotnet publish -c Release -o ./publish`
- Verify all necessary files are included in the publish output
- Test the published application runs independently
- Consider creating self-contained deployments if needed: `dotnet publish -c Release --self-contained -r <runtime-identifier>`

### Documentation Updates
- Update README files with new build and run instructions
- Document any breaking changes from the migration
- Update deployment documentation to reflect .NET (not .NET Framework) requirements
- Note any changes in system requirements or dependencies

## 7. Final Validation Checklist

- [ ] All projects build without errors or warnings
- [ ] Unit tests pass completely
- [ ] Integration tests pass (if applicable)
- [ ] Application runs successfully on target platforms
- [ ] Configuration files load correctly
- [ ] External service connections work
- [ ] Performance is acceptable (compare with legacy version if possible)
- [ ] Logging and monitoring function correctly
- [ ] Error handling behaves as expected
- [ ] Security features remain intact

## 8. Post-Migration Optimization

### Consider Modern .NET Features
- Evaluate using minimal APIs (for web applications)
- Consider adopting nullable reference types for better null safety
- Review opportunities to use newer C# language features
- Assess performance improvements available in newer .NET versions

### Cleanup
- Remove unused NuGet packages
- Delete obsolete compatibility shims or workarounds
- Remove conditional compilation blocks that are no longer needed
- Archive or delete legacy .NET Framework-specific files