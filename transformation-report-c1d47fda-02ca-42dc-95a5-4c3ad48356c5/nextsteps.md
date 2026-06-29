# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility shims that may cause runtime issues.

## 3. Run Existing Tests

If a test project exists in the solution, execute the test suite:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review the output for any failing tests or runtime exceptions that were not caught at compile time.

## 4. Check for Windows-Specific API Usage

Even with a successful build, the code may reference Windows-specific APIs that will fail at runtime on Linux or macOS. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay attention to any `CA1416` platform compatibility warnings in the build output.

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies target `netstandard2.0`, `netstandard2.1`, or the specific .NET version you are using. Packages that only target `net4x` may have been resolved using compatibility mode and could behave unexpectedly.

```bash
dotnet list package --outdated
```

Update any outdated packages where a cross-platform compatible version is available.

## 6. Validate Runtime Behavior

Run the application directly to confirm it behaves as expected:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve:
- File system access (path separators differ between Windows and Unix)
- Database connections (verify connection strings and drivers)
- Reflection or dynamic code loading
- Registry access (not available on non-Windows platforms)

## 7. Publish a Self-Contained Build

Once runtime behavior is validated, produce a published output to verify the final artifact:

```bash
dotnet publish AdoCore.csproj --configuration Release --runtime win-x64 --self-contained true
dotnet publish AdoCore.csproj --configuration Release --runtime linux-x64 --self-contained true
```

Test the resulting binaries on their respective target platforms to confirm cross-platform compatibility end to end.