# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that may surface at runtime.

## 3. Review Removed or Replaced Dependencies

Check the `.csproj` file for any NuGet packages that were substituted during transformation. Verify that the replacement packages are the correct versions and are compatible with your target framework. Cross-reference with the [NuGet package compatibility matrix](https://www.nuget.org/packages) if needed.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify functional correctness:

```bash
dotnet test --configuration Release --verbosity normal
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs may behave differently or throw at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for platform-specific calls:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- File path assumptions (backslash vs. forward slash)

## 6. Test on Target Platform

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once testing is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to your target environment.

## 8. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been correctly migrated to `appsettings.json` or environment variables, and that the application reads them correctly at runtime using `Microsoft.Extensions.Configuration`.