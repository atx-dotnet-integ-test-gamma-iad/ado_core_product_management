# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet package restore to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts that may not surface as build errors but could cause runtime issues.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no configuration-specific issues:

```bash
dotnet build --configuration Release
```

## 4. Run Existing Tests

If the solution contains any test projects, run them to verify that existing behavior has been preserved after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for such usage:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with `SkiaSharp`)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) client/server APIs
- `System.Security.Permissions` and related CAS APIs

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only platform issues.

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Packages that target only `net45` or `netstandard1.x` may work but could lack newer API support. Visit [nuget.org](https://www.nuget.org) to verify compatibility and consider upgrading to actively maintained versions.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you want to bundle the .NET runtime with the output.