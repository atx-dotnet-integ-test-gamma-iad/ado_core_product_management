# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated package versions that may need to be updated.

### 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while not blocking, may indicate compatibility concerns with the target framework.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the transformation:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they reflect a regression introduced by the migration or a pre-existing issue.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm that the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime environment where the application will be deployed.

### 5. Review Removed or Changed APIs

Cross-platform .NET removes or modifies certain APIs that were available in .NET Framework. Manually review the code for usage of the following common problem areas:

- `System.Web` namespace (not available in .NET Core/.NET 5+)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` members that are no longer supported
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)
- Any P/Invoke calls targeting Windows-only native libraries

If any of these are present, they will require code-level changes to use supported alternatives.

### 6. Check for Platform-Specific Code

If the application is intended to run on non-Windows platforms, verify that no Windows-specific assumptions exist in the code, such as hardcoded file path separators or Windows-only system calls. Use `Path.Combine` and `Path.DirectorySeparatorChar` where applicable.

### 7. Validate Runtime Behavior

Run the application manually or through its entry point and exercise the primary workflows to confirm runtime behavior matches expectations from the original .NET Framework version.

### 8. Deployment

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm that all required assets, configuration files, and dependencies are present before deploying to the target environment.