# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility shims.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform-specific code paths.

## 4. Run the Test Suite

If the solution contains a test project, execute all tests to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, such as differences in:

- `System.Drawing` availability (requires the `System.Drawing.Common` package on non-Windows platforms)
- `System.Data` and ADO.NET provider behavior
- Globalization and encoding defaults
- Reflection behavior changes

## 5. Audit Platform-Specific Code

Because this project is named `AdoCore` and likely involves ADO.NET data access, review the following areas for platform compatibility:

- **Database drivers**: Ensure any database provider packages (e.g., `System.Data.SqlClient`, `Microsoft.Data.SqlClient`, `Npgsql`) are the cross-platform compatible versions.
- **Connection strings**: Confirm connection string formats are compatible with the updated providers.
- **Windows-only APIs**: Search the codebase for usages of `System.Data.OleDb` or `System.Data.Odbc`, as these have limited or no support on non-Windows platforms.

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any API usage that was available in .NET Framework but has been removed or changed in cross-platform .NET:

```bash
dotnet tool install -g dotnet-compatibility
```

Alternatively, review the official [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) relevant to your target framework version.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the build and tests explicitly on each target operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time.

```bash
dotnet test --configuration Release --runtime linux-x64
dotnet test --configuration Release --runtime win-x64
dotnet test --configuration Release --runtime osx-x64
```

## 8. Publish the Application

Once validation is complete, publish the project using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Use `--self-contained true` if you require the .NET runtime to be bundled with the output. Review the contents of the `publish` output directory before deploying to confirm all required assets are present.