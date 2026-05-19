# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific framework (e.g., `net472`), update it accordingly.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a clean build to confirm there are no hidden issues:

```bash
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns even if the build succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated before proceeding.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were historically Windows-only, such as:

- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows DLLs

These may compile successfully but will fail at runtime on non-Windows platforms. Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to assist with this.

## 6. Run the Application on Target Platforms

Execute the application on each platform you intend to support (e.g., Linux, macOS, Windows) and verify runtime behavior:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable differences, and any OS-specific behavior.

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support your target framework. You can inspect this via:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime(s):

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target. A full list of RIDs is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).