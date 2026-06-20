# Next Steps

The solution has no build errors following the transformation. The migration to cross-platform .NET appears to have completed successfully. The following steps outline how to validate, test, and deploy the project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or platform compatibility.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Behavior

Check the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to review include:

- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` usage (not available outside of ASP.NET Core)
- Windows Registry access (`Microsoft.Win32.Registry`) — only functional on Windows
- WCF server-side components — not supported on cross-platform .NET without community libraries
- `AppDomain` usage — partially supported; some members throw `PlatformNotSupportedException`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tooling to surface any remaining compatibility concerns.

## 5. Run the Application and Perform Smoke Testing

Start the application and perform basic functional verification:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Confirm that core workflows behave as expected and that no runtime exceptions are thrown due to missing platform support.

## 6. Review Target Framework Moniker (TFM)

Open the `AdoCore.csproj` file and confirm the target framework is set to a currently supported version:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project is targeting `net6.0` or `net7.0`, consider updating to `net8.0`, which is the current Long-Term Support (LTS) release.

## 7. Review Nullable Reference Type Annotations

If the project was migrated from .NET Framework, nullable reference type warnings may be present. Review the project file for the following setting:

```xml
<Nullable>enable</Nullable>
```

If enabled, address any resulting warnings to improve code correctness. If not yet enabled, consider enabling it incrementally.

## 8. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target platform (e.g., `win-x64`, `osx-x64`).

## 9. Verify Output Artifacts

Inspect the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.