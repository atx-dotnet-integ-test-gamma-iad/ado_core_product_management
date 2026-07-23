# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. The solution compiles without issues.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Verify that no warnings or errors appear during the restore process.

### 2. Build the Solution

Perform a full build to confirm the solution compiles cleanly:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

### 3. Run Unit Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --verbosity normal
```

Review test results carefully. A successful build does not guarantee that runtime logic is functioning as expected.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with your organization's supported runtime version.

### 5. Check for Platform-Specific API Usage

Even without build errors, the code may reference APIs that behave differently across operating systems. Use the .NET Compatibility Analyzer to surface any such issues:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to any `CA1416` platform compatibility warnings.

### 6. Run the Application

Execute the application on the target platform to verify end-to-end behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that previously relied on Windows-specific functionality such as the registry, COM interop, or Windows authentication.

### 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate for your deployment target:

**Framework-dependent:**
```bash
dotnet publish AdoCore.csproj --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish AdoCore.csproj --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.