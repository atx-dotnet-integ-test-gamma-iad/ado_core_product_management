# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility concerns, even if the build succeeds.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by API differences between .NET Framework and modern .NET.

## 4. Check for Windows-Specific API Usage

Even if the project builds successfully, certain APIs may only function correctly on Windows. Use the .NET Compatibility Analyzer or review the code manually for usages such as:

- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- COM interop
- `System.Drawing` (requires additional packages on Linux/macOS)

If cross-platform support is required, replace or conditionally compile these usages.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and inspect all `<PackageReference>` entries. Verify that each package supports the target framework by checking [nuget.org](https://www.nuget.org). Packages that previously targeted .NET Framework may have newer versions with cross-platform support.

```bash
dotnet list package --outdated
```

Update packages where appropriate:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as these are the standard configuration mechanisms in modern .NET.

## 7. Run on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any runtime issues that do not surface during compilation:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Or for a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder before deploying to the target environment.