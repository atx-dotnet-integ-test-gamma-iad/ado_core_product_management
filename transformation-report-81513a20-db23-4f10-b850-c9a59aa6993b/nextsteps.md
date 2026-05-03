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

Review the output for any warnings about packages that do not support the target framework or that have been substituted with compatibility shims.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform-specific code paths.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so any failing tests should be investigated before proceeding.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that were available in .NET Framework but have been removed or altered in cross-platform .NET. Common areas to review include:

- `System.Web` references (not available outside of ASP.NET Core)
- `AppDomain` usage (partially supported)
- Registry access (`Microsoft.Win32.Registry`) — only functional on Windows
- `System.Drawing` — requires the `System.Drawing.Common` package and may have OS restrictions
- `BinaryFormatter` — disabled by default in .NET 5 and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility issues.

## 6. Run the Application

Execute the application directly to confirm it starts and behaves as expected:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

If the project is a library rather than an executable, write or run a small integration test or console harness that exercises its primary functionality.

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate for your deployment target.

**Framework-dependent (smaller output, requires .NET runtime on target machine):**

```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (includes the runtime, no dependency on installed .NET):**

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `linux-arm64`).

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and assets are present. Run the published output on the target platform to perform a final smoke test before distributing or deploying.