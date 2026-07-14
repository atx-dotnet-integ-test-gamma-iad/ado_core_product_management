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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and the new .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-only API calls that may compile but fail at runtime on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop calls
- `AppDomain` usage patterns that changed between runtimes

## 5. Validate NuGet Package Compatibility

Review all NuGet package references in `AdoCore.csproj` and confirm each package supports the target framework. Check [nuget.org](https://www.nuget.org) for any packages that may have a newer version with cross-platform support.

```bash
dotnet list package --outdated
```

Update packages where appropriate:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues that do not appear during compilation.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Review the contents of the `publish` output folder to confirm all required assets are present before deploying.