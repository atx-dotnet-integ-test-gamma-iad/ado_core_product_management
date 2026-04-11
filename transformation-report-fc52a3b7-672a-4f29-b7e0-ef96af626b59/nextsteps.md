# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages. Replace any packages that target only .NET Framework with their cross-platform equivalents if warnings are present.

## 3. Build the Solution

Perform a clean build to confirm there are no issues:

```bash
dotnet build --configuration Release
```

Verify that the build output reports zero errors and review any warnings that may indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review the test results and address any failing tests. Failing tests after migration often indicate areas where platform-specific behavior has changed.

## 5. Validate Runtime Behavior

Run the application and exercise its core functionality manually or through integration tests:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity and ADO.NET operations, as driver availability and connection string formats can differ across platforms.
- File system paths, since Windows-style paths (`\`) are not valid on Linux/macOS. Use `Path.Combine` where applicable.
- Any use of the Windows registry or Windows-specific APIs, which will not be available on non-Windows platforms.

## 6. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Review analyzer warnings and replace or conditionally compile any APIs that are not supported cross-platform.

## 7. Test on Target Platforms

If cross-platform support is a goal, build and run the application on each intended operating system (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
dotnet publish --configuration Release --runtime osx-x64 --self-contained false
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

## 8. Publish the Application

Once validation is complete, publish the final output:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm all required files and dependencies are present before deploying to the target environment.